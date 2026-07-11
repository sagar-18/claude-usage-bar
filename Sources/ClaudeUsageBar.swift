import Cocoa
import ServiceManagement

// MARK: - Color helpers

func rgb(_ r: Double, _ g: Double, _ b: Double) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
}
func ramp(_ p: Double, _ c1: NSColor, _ c2: NSColor, _ c3: NSColor, _ c4: NSColor) -> NSColor {
    if p >= 90 { return c4 }
    if p >= 70 { return c3 }
    if p >= 40 { return c2 }
    return c1
}

// MARK: - Themes

enum Theme: String, CaseIterable {
    case severity   = "Severity"
    case ocean      = "Ocean"
    case claude     = "Claude"
    case identity   = "Per-Metric"
    case mono       = "Minimal"
    case catppuccin = "Catppuccin"
    case nord       = "Nord"
    case dracula    = "Dracula"
    case terminal   = "Terminal"

    static var current: Theme {
        get { Theme(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .ocean }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "theme") }
    }

    var symbol: String {
        switch self {
        case .severity: return "gauge.with.dots.needle.50percent"
        case .ocean:    return "drop.fill"
        case .claude:   return "sparkles"
        case .identity: return "circle.hexagongrid.fill"
        case .mono:     return "circle.fill"
        case .catppuccin: return "cup.and.saucer.fill"
        case .nord:       return "snowflake"
        case .dracula:    return "moon.fill"
        case .terminal:   return "terminal.fill"
        }
    }

    func color(kind: String, pct: Double) -> NSColor {
        switch self {
        case .severity:
            return ramp(pct, rgb(0.133,0.773,0.369), rgb(0.984,0.749,0.141),
                             rgb(0.976,0.451,0.086), rgb(0.937,0.267,0.267))
        case .ocean:
            return ramp(pct, rgb(0.078,0.722,0.651), rgb(0.231,0.510,0.965),
                             rgb(0.416,0.384,0.945), rgb(0.925,0.286,0.600))
        case .claude:
            return ramp(pct, rgb(0.906,0.706,0.596), rgb(0.855,0.588,0.431),
                             rgb(0.851,0.467,0.341), rgb(0.722,0.290,0.180))
        case .identity:
            switch kind {
            case "session":       return rgb(0.231,0.510,0.965)
            case "weekly_all":    return rgb(0.545,0.361,0.965)
            case "weekly_scoped": return rgb(0.976,0.451,0.086)
            case "monthly":       return rgb(0.545,0.361,0.965)
            default:              return rgb(0.392,0.455,0.545)
            }
        case .mono:
            return rgb(0.851,0.467,0.341)
        case .catppuccin:
            return ramp(pct, rgb(0.651,0.890,0.631), rgb(0.537,0.706,0.980),
                             rgb(0.980,0.702,0.529), rgb(0.953,0.545,0.659))
        case .nord:
            return ramp(pct, rgb(0.533,0.753,0.816), rgb(0.506,0.631,0.757),
                             rgb(0.369,0.506,0.675), rgb(0.749,0.380,0.416))
        case .dracula:
            return ramp(pct, rgb(0.314,0.980,0.482), rgb(0.545,0.914,0.992),
                             rgb(1.000,0.722,0.424), rgb(1.000,0.333,0.333))
        case .terminal:
            return ramp(pct, rgb(0.224,1.000,0.478), rgb(0.180,0.851,0.408),
                             rgb(0.718,0.878,0.263), rgb(1.000,0.420,0.290))
        }
    }

    func accent(worst: Double, worstKind: String) -> NSColor {
        switch self {
        case .identity: return color(kind: worstKind, pct: worst)
        case .mono:     return rgb(0.851,0.467,0.341)
        default:        return color(kind: "", pct: worst)
        }
    }
}

// MARK: - Menu bar style

enum BarStyle: String, CaseIterable {
    case full    = "Full"
    case compact = "Compact (worst limit)"
    case session = "5-hour session only"
    case ring    = "Ring icon (worst limit)"

    // Narrow default: crowded/notched menu bars silently hide wide items, and a
    // hidden icon looks like a broken install to a first-time user.
    static var current: BarStyle {
        get { BarStyle(rawValue: UserDefaults.standard.string(forKey: "barStyle") ?? "") ?? .session }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "barStyle") }
    }
}

// MARK: - Provider

enum Provider: String, CaseIterable {
    case claude = "Claude"
    case codex  = "Codex"

    static var current: Provider {
        get { Provider(rawValue: UserDefaults.standard.string(forKey: "provider") ?? "") ?? .claude }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "provider") }
    }
    var glyph: String { self == .codex ? "⬡" : "◐" }
    var appTitle: String { self == .codex ? "Codex Usage" : "Claude Usage" }
    var usageURL: String {
        self == .codex ? "https://chatgpt.com/codex/settings/usage"
                       : "https://claude.ai/settings/usage"
    }
}

// MARK: - Dropdown layout

enum LayoutStyle: String, CaseIterable {
    case classic  = "Classic"
    case rings    = "Rings"
    case segments = "Segments"
    case trend    = "Trend + forecast"

    static var current: LayoutStyle {
        get { LayoutStyle(rawValue: UserDefaults.standard.string(forKey: "layoutStyle") ?? "") ?? .classic }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "layoutStyle") }
    }
}

// MARK: - Usage history (persisted locally; feeds the Trend layout's forecast)

enum UsageHistory {
    // Per-provider buckets so switching providers doesn't blend the curves.
    private static var key: String {
        Provider.current == .codex ? "usageHistory-codex" : "usageHistory"
    }

    static func record(_ limits: [[String: Any]]) {
        var arr = (UserDefaults.standard.array(forKey: key) as? [[String: Any]]) ?? []
        let now = Date().timeIntervalSince1970
        for l in limits {
            guard let kind = l["kind"] as? String else { continue }
            let pct = (l["percent"] as? NSNumber)?.doubleValue ?? 0
            arr.append(["t": now, "k": kind, "p": pct])
        }
        let cutoff = now - 7 * 24 * 3600
        arr = arr.filter { (($0["t"] as? Double) ?? 0) >= cutoff }
        UserDefaults.standard.set(arr, forKey: key)
    }

    static func series(kind: String, hours: Double) -> [(t: Double, p: Double)] {
        let arr = (UserDefaults.standard.array(forKey: key) as? [[String: Any]]) ?? []
        let cutoff = Date().timeIntervalSince1970 - hours * 3600
        return arr.compactMap { e -> (t: Double, p: Double)? in
            guard let t = e["t"] as? Double, t >= cutoff,
                  (e["k"] as? String) == kind,
                  let p = (e["p"] as? NSNumber)?.doubleValue else { return nil }
            return (t, p)
        }.sorted { $0.t < $1.t }
    }

    /// Linear projection of when this limit hits 100%, from points since the
    /// last reset. Nil when there's no meaningful upward signal.
    static func forecast(kind: String, current: Double) -> Date? {
        guard current < 100 else { return Date() }
        var s = series(kind: kind, hours: kind == "session" ? 4 : 48)
        var start = 0
        for i in 1..<max(s.count, 1) where i < s.count && s[i].p < s[i-1].p - 1 { start = i }
        if start > 0 { s = Array(s[start...]) }
        guard s.count >= 2 else { return nil }
        let dt = s[s.count-1].t - s[0].t
        let dp = s[s.count-1].p - s[0].p
        guard dt > 600, dp > 0.5 else { return nil }
        return Date(timeIntervalSince1970: s[s.count-1].t + (100 - current) / (dp / dt))
    }
}

// MARK: - Generic helpers

func makeLabel(_ s: String, size: CGFloat, weight: NSFont.Weight,
               color: NSColor, align: NSTextAlignment = .left,
               mono: Bool = false) -> NSTextField {
    let f = NSTextField(labelWithString: s)
    f.font = mono ? .monospacedDigitSystemFont(ofSize: size, weight: weight)
                  : .systemFont(ofSize: size, weight: weight)
    f.textColor = color
    f.alignment = align
    return f
}

// MARK: - Rounded progress bar

final class BarView: NSView {
    private let pct: Double
    private let fill: NSColor
    init(pct: Double, fill: NSColor, width: CGFloat) {
        self.pct = pct; self.fill = fill
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 7))
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.height / 2
        NSColor.quaternaryLabelColor.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: r, yRadius: r).fill()
        let frac = CGFloat(min(max(pct, 0), 100) / 100)
        let w = max(bounds.width * frac, frac > 0 ? bounds.height : 0)
        guard w > 0 else { return }
        let fillRect = NSRect(x: 0, y: 0, width: w, height: bounds.height)
        NSBezierPath(roundedRect: fillRect, xRadius: r, yRadius: r).setClip()
        let grad = NSGradient(colors: [fill.blended(withFraction: 0.20, of: .white) ?? fill, fill])
        grad?.draw(in: fillRect, angle: 0)
    }
}

// MARK: - One limit row

final class RowView: NSView {
    init(icon: String, name: String, pct: Double, reset: String, active: Bool, color: NSColor) {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 58))
        let W = frame.width

        let iv = NSImageView(frame: NSRect(x: 16, y: 34, width: 15, height: 15))
        let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        iv.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)
        iv.contentTintColor = color
        addSubview(iv)

        let nameField = makeLabel(name, size: 13, weight: .semibold, color: .labelColor)
        nameField.frame = NSRect(x: 40, y: 33, width: 190, height: 18)
        addSubview(nameField)

        if active {
            let dot = makeLabel("● LIVE", size: 8, weight: .bold, color: color)
            let w = nameField.attributedStringValue.size().width
            dot.frame = NSRect(x: 40 + min(w, 190) + 6, y: 36, width: 46, height: 12)
            addSubview(dot)
        }

        let pctField = makeLabel("\(Int(pct))%", size: 14, weight: .bold,
                                 color: color, align: .right, mono: true)
        pctField.frame = NSRect(x: W - 74, y: 32, width: 58, height: 20)
        addSubview(pctField)

        let bar = BarView(pct: pct, fill: color, width: W - 40 - 16)
        bar.frame.origin = NSPoint(x: 40, y: 22)
        addSubview(bar)

        if !reset.isEmpty {
            let r = makeLabel(reset, size: 11, weight: .regular, color: .secondaryLabelColor)
            r.frame = NSRect(x: 40, y: 5, width: W - 56, height: 14)
            addSubview(r)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Rings layout

final class RingGaugeView: NSView {
    private let pct: Double
    private let color: NSColor
    init(pct: Double, color: NSColor) {
        self.pct = pct; self.color = color
        super.init(frame: NSRect(x: 0, y: 0, width: 52, height: 52))
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        let c = NSPoint(x: bounds.midX, y: bounds.midY)
        let track = NSBezierPath()
        track.appendArc(withCenter: c, radius: 21, startAngle: 0, endAngle: 360)
        track.lineWidth = 5
        NSColor.quaternaryLabelColor.setStroke()
        track.stroke()
        let p = min(max(pct, 0), 100)
        if p > 0 {
            let arc = NSBezierPath()
            arc.appendArc(withCenter: c, radius: 21, startAngle: 90,
                          endAngle: 90 - 360 * CGFloat(p) / 100, clockwise: true)
            arc.lineWidth = 5
            arc.lineCapStyle = .round
            color.setStroke()
            arc.stroke()
        }
        let s = "\(Int(pct))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.labelColor,
        ]
        let size = s.size(withAttributes: attrs)
        s.draw(at: NSPoint(x: c.x - size.width / 2, y: c.y - size.height / 2), withAttributes: attrs)
    }
}

final class RingsRowView: NSView {
    init(gauges: [(label: String, reset: String, pct: Double, color: NSColor)]) {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 100))
        let n = CGFloat(max(gauges.count, 1))
        let slot = (frame.width - 32) / n
        for (i, g) in gauges.enumerated() {
            let cx = 16 + slot * CGFloat(i) + slot / 2
            let ring = RingGaugeView(pct: g.pct, color: g.color)
            ring.frame.origin = NSPoint(x: cx - 26, y: 38)
            addSubview(ring)
            let lab = makeLabel(g.label, size: 11, weight: .semibold, color: .labelColor, align: .center)
            lab.frame = NSRect(x: cx - slot / 2, y: 20, width: slot, height: 15)
            addSubview(lab)
            let res = makeLabel(g.reset, size: 9.5, weight: .regular, color: .secondaryLabelColor, align: .center)
            res.frame = NSRect(x: cx - slot / 2, y: 6, width: slot, height: 12)
            addSubview(res)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Segments layout

final class SegBarView: NSView {
    private let pct: Double
    private let fill: NSColor
    init(pct: Double, fill: NSColor, width: CGFloat) {
        self.pct = pct; self.fill = fill
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 7))
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        let n = 10
        let gap: CGFloat = 2
        let cell = (bounds.width - gap * CGFloat(n - 1)) / CGFloat(n)
        let filled = Int((min(max(pct, 0), 100) / 10).rounded())
        for i in 0..<n {
            let rect = NSRect(x: CGFloat(i) * (cell + gap), y: 0, width: cell, height: bounds.height)
            if i < filled { fill.setFill() }
            else if i >= 9 { NSColor.systemRed.withAlphaComponent(0.25).setFill() }
            else if i >= 7 { NSColor.systemOrange.withAlphaComponent(0.22).setFill() }
            else { NSColor.quaternaryLabelColor.setFill() }
            NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2).fill()
        }
    }
}

final class SegRowView: NSView {
    init(icon: String, name: String, pct: Double, reset: String, active: Bool, color: NSColor) {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 58))
        let W = frame.width
        let iv = NSImageView(frame: NSRect(x: 16, y: 34, width: 15, height: 15))
        iv.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        iv.contentTintColor = color
        addSubview(iv)
        let nameField = makeLabel(name, size: 13, weight: .semibold, color: .labelColor)
        nameField.frame = NSRect(x: 40, y: 33, width: 190, height: 18)
        addSubview(nameField)
        if active {
            let dot = makeLabel("● LIVE", size: 8, weight: .bold, color: color)
            let w = nameField.attributedStringValue.size().width
            dot.frame = NSRect(x: 40 + min(w, 190) + 6, y: 36, width: 46, height: 12)
            addSubview(dot)
        }
        let pctField = makeLabel("\(Int(pct))%", size: 14, weight: .bold,
                                 color: color, align: .right, mono: true)
        pctField.frame = NSRect(x: W - 74, y: 32, width: 58, height: 20)
        addSubview(pctField)
        let bar = SegBarView(pct: pct, fill: color, width: W - 40 - 16)
        bar.frame.origin = NSPoint(x: 40, y: 22)
        addSubview(bar)
        if !reset.isEmpty {
            let r = makeLabel(reset, size: 11, weight: .regular, color: .secondaryLabelColor)
            r.frame = NSRect(x: 40, y: 5, width: W - 56, height: 14)
            addSubview(r)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Trend layout

final class SparkView: NSView {
    private let points: [(t: Double, p: Double)]
    private let color: NSColor
    init(points: [(t: Double, p: Double)], color: NSColor, width: CGFloat) {
        self.points = points; self.color = color
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 26))
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.quaternaryLabelColor.setFill()
        NSRect(x: 0, y: 0, width: bounds.width, height: 1).fill()
        NSRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1).fill()
        guard points.count >= 2 else { return }
        let t0 = points[0].t, t1 = points[points.count - 1].t
        let span = max(t1 - t0, 1)
        let path = NSBezierPath()
        for (i, pt) in points.enumerated() {
            let x = CGFloat((pt.t - t0) / span) * bounds.width
            let y = CGFloat(min(max(pt.p, 0), 100) / 100) * (bounds.height - 4) + 2
            if i == 0 { path.move(to: NSPoint(x: x, y: y)) }
            else { path.line(to: NSPoint(x: x, y: y)) }
        }
        path.lineWidth = 1.5
        color.setStroke()
        path.stroke()
    }
}

final class TrendRowView: NSView {
    init(icon: String, name: String, pct: Double, caption: String, active: Bool,
         color: NSColor, points: [(t: Double, p: Double)]) {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 78))
        let W = frame.width
        let iv = NSImageView(frame: NSRect(x: 16, y: 56, width: 15, height: 15))
        iv.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        iv.contentTintColor = color
        addSubview(iv)
        let nameField = makeLabel(name, size: 13, weight: .semibold, color: .labelColor)
        nameField.frame = NSRect(x: 40, y: 55, width: 190, height: 18)
        addSubview(nameField)
        if active {
            let dot = makeLabel("● LIVE", size: 8, weight: .bold, color: color)
            let w = nameField.attributedStringValue.size().width
            dot.frame = NSRect(x: 40 + min(w, 190) + 6, y: 58, width: 46, height: 12)
            addSubview(dot)
        }
        let pctField = makeLabel("\(Int(pct))%", size: 14, weight: .bold,
                                 color: color, align: .right, mono: true)
        pctField.frame = NSRect(x: W - 74, y: 54, width: 58, height: 20)
        addSubview(pctField)
        let spark = SparkView(points: points, color: color, width: W - 40 - 16)
        spark.frame.origin = NSPoint(x: 40, y: 24)
        addSubview(spark)
        let cap = makeLabel(caption, size: 10.5, weight: .regular, color: .secondaryLabelColor)
        cap.frame = NSRect(x: 40, y: 5, width: W - 56, height: 14)
        addSubview(cap)
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Stat row (icon + label + right-aligned value; used for Codex activity)

final class StatRowView: NSView {
    init(icon: String, name: String, value: String, color: NSColor) {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 32))
        let iv = NSImageView(frame: NSRect(x: 16, y: 8, width: 15, height: 15))
        iv.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        iv.contentTintColor = color
        addSubview(iv)
        let nameField = makeLabel(name, size: 13, weight: .semibold, color: .labelColor)
        nameField.frame = NSRect(x: 40, y: 7, width: 110, height: 18)
        addSubview(nameField)
        let valueField = makeLabel(value, size: 12.5, weight: .semibold, color: color,
                                   align: .right, mono: true)
        valueField.frame = NSRect(x: 150, y: 7, width: frame.width - 166, height: 18)
        addSubview(valueField)
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Header

final class HeaderView: NSView {
    init(worst: Double, accent: NSColor, themeSymbol: String, title: String, subtitle: String) {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 52))

        let iv = NSImageView(frame: NSRect(x: 16, y: 15, width: 22, height: 22))
        let cfg = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        iv.image = NSImage(systemSymbolName: themeSymbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)
        iv.contentTintColor = accent
        addSubview(iv)

        let titleField = makeLabel(title, size: 15, weight: .bold, color: .labelColor)
        titleField.frame = NSRect(x: 46, y: 26, width: 200, height: 20)
        addSubview(titleField)

        let sub = makeLabel(subtitle, size: 11, weight: .regular,
                            color: .secondaryLabelColor)
        sub.frame = NSRect(x: 46, y: 10, width: 200, height: 14)
        addSubview(sub)

        let status = worst >= 90 ? "CRITICAL" : worst >= 70 ? "HIGH" : worst >= 40 ? "MODERATE" : "HEALTHY"
        let pill = makeLabel(status, size: 9, weight: .heavy, color: accent, align: .right)
        pill.frame = NSRect(x: frame.width - 116, y: 19, width: 100, height: 14)
        addSubview(pill)
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Separator

final class SepView: NSView {
    init() { super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 9)) }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.separatorColor.setFill()
        NSRect(x: 16, y: 4, width: bounds.width - 32, height: 1).fill()
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var updateTimer: Timer?
    var lastLimits: [[String: Any]]?
    private var backoff: TimeInterval = 0
    private var latestVersion: String?   // set when GitHub has a newer release
    private var lastUpdateCheck: Date?   // throttles the menu-open update check
    private var updating = false         // true while `brew` rebuilds in the background
    private var lastSuccess: Date?       // when we last parsed fresh usage data
    private var planName: String?        // subscriptionType from the Keychain ("max", "pro", …)
    private var planTier: String?        // "20x"/"5x" from rateLimitTier, when present
    // Codex activity (tokens/turns) from the analytics endpoint — the only usage
    // signal Business/Enterprise seats get, and a nice extra for everyone else.
    private var codexActivity: (todayTokens: Int, todayTurns: Int, weekTokens: Int, weekTurns: Int)?
    private var freshItem: NSMenuItem?   // the "Updated Xm ago" row, re-stamped on menu open

    /// Whether the Claude Code OAuth token works. The token lives ~12h and only
    /// Claude Code can renew it — when it lapses we must say so instead of
    /// silently showing stale numbers.
    private enum AuthState { case unknown, ok, expired, missing }
    private var authState: AuthState = .unknown
    static var refreshMinutes: Int {
        get { let v = UserDefaults.standard.integer(forKey: "refreshMinutes"); return v == 0 ? 5 : v }
        set { UserDefaults.standard.set(newValue, forKey: "refreshMinutes") }
    }
    private var normalInterval: TimeInterval { TimeInterval(AppDelegate.refreshMinutes * 60) }

    /// Falls back to the build-time version when run outside the .app bundle.
    /// Keep the fallback in sync with VERSION in build.sh.
    static let currentVersion =
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.4.0"

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "◐ …"
        // Enable Launch at Login on first run only — a menu-bar tracker is
        // pointless if it dies on reboot. One-shot so a user's later opt-out sticks.
        if #available(macOS 13.0, *), !UserDefaults.standard.bool(forKey: "didDefaultLoginItem") {
            UserDefaults.standard.set(true, forKey: "didDefaultLoginItem")
            if SMAppService.mainApp.status == .notRegistered {
                try? SMAppService.mainApp.register()
            }
        }
        tick()
        // Check for updates shortly after launch, then daily.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in self?.checkForUpdates() }
        updateTimer = Timer.scheduledTimer(withTimeInterval: 24 * 3600, repeats: true) { [weak self] _ in
            self?.checkForUpdates()
        }
        // Refetch right after wake — timers sleep with the machine, and the
        // token often expires overnight; don't sit on stale data until the
        // next scheduled poll.
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.backoff = 0
            self?.scheduleNext(3)
            self?.checkForUpdates()
        }
    }

    /// A 24h timer alone leaves releases invisible for up to a day (longer with
    /// sleep, which pauses timers). Also check whenever the menu is opened, at
    /// most once an hour — the moment the user looks is the moment it matters.
    func menuWillOpen(_ menu: NSMenu) {
        // The freshness label is baked in at render time, which happens right
        // after each successful fetch — left alone it would read "just now"
        // forever. Re-stamp it with the real age at the moment of opening.
        freshItem?.attributedTitle = NSAttributedString(string: freshnessText, attributes: [
            .foregroundColor: NSColor.tertiaryLabelColor,
            .font: NSFont.systemFont(ofSize: 11),
        ])
        if let last = lastUpdateCheck, -last.timeIntervalSinceNow < 3600 { return }
        checkForUpdates()
    }

    // MARK: - Scheduling with exponential backoff (handles the endpoint's 429s)

    private func scheduleNext(_ after: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: after, repeats: false) { [weak self] _ in self?.tick() }
    }
    private func tick() {
        fetch { [weak self] ok in
            guard let self = self else { return }
            if ok {
                self.backoff = 0
                self.scheduleNext(self.normalInterval)
            } else {
                self.backoff = self.backoff == 0 ? 60 : min(self.backoff * 2, 900)
                self.scheduleNext(self.backoff)
            }
        }
    }
    @objc private func refreshNow() {
        backoff = 0
        statusItem.button?.appearsDisabled = true   // dim the icon so the click visibly did something
        fetch { [weak self] ok in
            guard let self = self else { return }
            self.statusItem.button?.appearsDisabled = false
            self.scheduleNext(ok ? self.normalInterval : 60)
        }
    }

    /// Runs the network call OFF the main thread; parses + renders + reports success on main.
    private func fetch(_ completion: @escaping (Bool) -> Void) {
        let provider = Provider.current
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let data = provider == .codex ? self?.codexQuery() : self?.runQuery()
            let plan = provider == .codex ? (name: nil, tier: nil) : (self?.readPlan() ?? (name: nil, tier: nil))
            var codexPlan: String?
            var activity: (todayTokens: Int, todayTurns: Int, weekTokens: Int, weekTurns: Int)?
            var parsed: [[String: Any]]?
            var errType = ""
            if let data = data,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let err = obj["error"] as? [String: Any] {
                    errType = err["type"] as? String ?? ""
                } else if provider == .codex {
                    let usage = obj["usage"] as? [String: Any] ?? obj
                    parsed = Self.mapCodex(usage)
                    codexPlan = usage["plan_type"] as? String
                    activity = Self.mapActivity(obj["activity"] as? [String: Any])
                } else if let ls = obj["limits"] as? [[String: Any]] {
                    parsed = ls
                }
            }
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard provider == Provider.current else { completion(false); return }   // switched mid-flight — drop
                if provider == .codex {
                    if let cp = codexPlan { self.planName = cp; self.planTier = nil }
                    if let act = activity { self.codexActivity = act }
                }
                else if let p = plan.name { self.planName = p; self.planTier = plan.tier }
                if let ls = parsed {
                    self.lastLimits = ls
                    self.lastSuccess = Date()
                    self.authState = .ok
                    UsageHistory.record(ls)
                } else if errType == "authentication_error" {
                    self.authState = .expired
                } else if errType == "no_token" {
                    self.authState = .missing
                }
                // Any other failure (network blip, 429) keeps the prior authState.
                self.render()
                completion(parsed != nil)
            }
        }
    }

    /// Self-contained: read the Claude Code OAuth token from the Keychain and call the
    /// usage endpoint. No user input is interpolated, so there is no shell-injection surface.
    private func runQuery() -> Data? {
        let cmd = """
        export PATH=/usr/bin:/bin
        TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
          | python3 -c 'import sys,json; print(json.load(sys.stdin)["claudeAiOauth"]["accessToken"])' 2>/dev/null)
        [ -z "$TOKEN" ] && { echo '{"type":"error","error":{"type":"no_token"}}'; exit 0; }
        curl -s --max-time 8 https://api.anthropic.com/api/oauth/usage \
          -H "Authorization: Bearer $TOKEN" \
          -H "anthropic-beta: oauth-2025-04-20" \
          -H "User-Agent: claude-code/2.1.197"
        """
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", cmd]
        let out = Pipe()
        task.standardOutput = out
        task.standardError = Pipe()
        do { try task.run() } catch { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return data
    }

    /// Codex counterpart of runQuery: reads the OAuth token from ~/.codex/auth.json
    /// (written by the Codex CLI) and calls the ChatGPT usage endpoint. Emits the
    /// same synthesized error JSON shapes fetch() already understands.
    private func codexQuery() -> Data? {
        let cmd = """
        export PATH=/usr/bin:/bin
        AUTH="$HOME/.codex/auth.json"
        [ -f "$AUTH" ] || { echo '{"error":{"type":"no_token"}}'; exit 0; }
        TOKEN=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["tokens"]["access_token"])' "$AUTH" 2>/dev/null)
        ACCT=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["tokens"].get("account_id",""))' "$AUTH" 2>/dev/null)
        [ -z "$TOKEN" ] && { echo '{"error":{"type":"no_token"}}'; exit 0; }
        RESP=$(curl -s --max-time 8 -w "\\n%{http_code}" https://chatgpt.com/backend-api/wham/usage \\
          -H "Authorization: Bearer $TOKEN" \\
          -H "Accept: application/json" \\
          -H "ChatGPT-Account-Id: $ACCT" \\
          -H "User-Agent: claude-usage-bar")
        CODE=$(printf '%s' "$RESP" | tail -1)
        if [ "$CODE" = "401" ] || [ "$CODE" = "403" ]; then echo '{"error":{"type":"authentication_error"}}'; exit 0; fi
        BODY=$(printf '%s' "$RESP" | sed '$d')
        END=$(date +%Y-%m-%d); START=$(date -v-6d +%Y-%m-%d)
        ACT=$(curl -s --max-time 8 "https://chatgpt.com/backend-api/wham/analytics/daily-workspace-usage-counts?start_date=$START&end_date=$END&group_by=day&workspace_user=true" \\
          -H "Authorization: Bearer $TOKEN" \\
          -H "Accept: application/json" \\
          -H "ChatGPT-Account-Id: $ACCT" \\
          -H "User-Agent: claude-usage-bar")
        case "$BODY" in "{"*) ;; *) BODY='{}';; esac
        case "$ACT" in "{"*) ;; *) ACT='{}';; esac
        printf '{"usage":%s,"activity":%s}' "$BODY" "$ACT"
        """
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", cmd]
        let out = Pipe()
        task.standardOutput = out
        task.standardError = Pipe()
        do { try task.run() } catch { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return data
    }

    /// Converts the Codex usage response into the same limits array the Claude
    /// endpoint returns, so every existing layout/theme/style renders it as-is.
    private static func mapCodex(_ obj: [String: Any]) -> [[String: Any]] {
        var limits: [[String: Any]] = []
        let rl = obj["rate_limit"] as? [String: Any] ?? [:]
        let iso = ISO8601DateFormatter()
        func convert(_ w: [String: Any]?, fallbackHours: Double) {
            guard let w = w, let p = w["used_percent"] as? NSNumber else { return }
            // Window length varies by plan: Plus/Pro get 5h + weekly, Go gets a
            // single 30-day window. Label by what the API says, not by position.
            let secs = (w["limit_window_seconds"] as? Double) ?? (fallbackHours * 3600)
            let hours = secs / 3600
            let kind: String, label: String, short: String
            if hours <= 24 {
                kind = "session"; label = "\(Int(hours))-hour session"; short = "\(Int(hours))h \(p.intValue)%"
            } else if hours <= 24 * 14 {
                kind = "weekly_all"; label = "Weekly"; short = "wk \(p.intValue)%"
            } else {
                kind = "monthly"; label = "Monthly"; short = "mo \(p.intValue)%"
            }
            var entry: [String: Any] = ["kind": kind, "percent": p, "is_active": false,
                                        "label": label, "short": short]
            var reset: Date?
            if let at = w["reset_at"] as? Double { reset = Date(timeIntervalSince1970: at) }
            else if let after = w["reset_after_seconds"] as? Double { reset = Date().addingTimeInterval(after) }
            if let reset = reset { entry["resets_at"] = iso.string(from: reset) }
            limits.append(entry)
        }
        convert(rl["primary_window"] as? [String: Any], fallbackHours: 5)
        convert(rl["secondary_window"] as? [String: Any], fallbackHours: 24 * 7)
        return limits
    }

    private static func mapActivity(_ a: [String: Any]?) -> (todayTokens: Int, todayTurns: Int, weekTokens: Int, weekTurns: Int)? {
        guard let rows = a?["data"] as? [[String: Any]], !rows.isEmpty else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = fmt.string(from: Date())
        var todayTok = 0, todayTurns = 0, weekTok = 0, weekTurns = 0
        for r in rows {
            let totals = r["totals"] as? [String: Any] ?? [:]
            let tok = (totals["text_total_tokens"] as? NSNumber)?.intValue ?? 0
            let turns = (totals["turns"] as? NSNumber)?.intValue ?? 0
            weekTok += tok
            weekTurns += turns
            if (r["date"] as? String) == today { todayTok = tok; todayTurns = turns }
        }
        return (todayTok, todayTurns, weekTok, weekTurns)
    }

    /// Reads subscriptionType ("max", "pro", …) and the "20x"/"5x" multiplier
    /// from rateLimitTier, both from the same Keychain item as the token.
    private func readPlan() -> (name: String?, tier: String?) {
        let cmd = """
        export PATH=/usr/bin:/bin
        security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
          | python3 -c 'import sys,json; d=json.load(sys.stdin)["claudeAiOauth"]; print(d.get("subscriptionType","")); print(d.get("rateLimitTier",""))' 2>/dev/null
        """
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", cmd]
        let out = Pipe()
        task.standardOutput = out
        task.standardError = Pipe()
        do { try task.run() } catch { return (nil, nil) }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        let lines = (String(data: data, encoding: .utf8) ?? "")
            .split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        let name = lines.count > 0 && !lines[0].isEmpty ? lines[0] : nil
        // rateLimitTier looks like "default_claude_max_20x" — surface only the
        // clean "20x" part, and nothing at all if the format ever changes.
        var tier: String?
        if lines.count > 1, let m = lines[1].range(of: #"\d+x$"#, options: .regularExpression) {
            tier = String(lines[1][m])
        }
        return (name, tier)
    }

    private func resetsIn(_ iso: String?) -> String {
        guard let iso = iso else { return "" }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = fmt.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
        guard let d = date else { return "" }
        let secs = d.timeIntervalSinceNow
        if secs <= 0 { return "resetting now" }
        let h = Int(secs) / 3600, m = (Int(secs) % 3600) / 60
        let days = h / 24
        if days >= 1 { return "resets in \(days)d \(h % 24)h" }
        return h > 0 ? "resets in \(h)h \(m)m" : "resets in \(m)m"
    }

    private func iconFor(_ kind: String) -> String {
        switch kind {
        case "session": return "clock.fill"
        case "weekly_all": return "calendar"
        case "monthly": return "calendar.circle.fill"
        case "weekly_scoped": return "sparkles"
        default: return "gauge.medium"
        }
    }

    private func forecastCaption(kind: String, pct: Double, reset: String) -> String {
        let resetPart = reset.isEmpty ? "" : " · \(reset)"
        if let eta = UsageHistory.forecast(kind: kind, current: pct) {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE h a"
            return "at this pace: 100% ≈ \(fmt.string(from: eta))\(resetPart)"
        }
        let hasHistory = UsageHistory.series(kind: kind, hours: kind == "session" ? 5 : 72).count >= 2
        return (hasHistory ? "steady — no runout expected" : "collecting history…") + resetPart
    }

    /// Tiny ring gauge for the menu-bar button (BarStyle.ring).
    private func ringImage(pct: Double, color: NSColor) -> NSImage {
        NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            let c = NSPoint(x: 9, y: 9)
            let track = NSBezierPath()
            track.appendArc(withCenter: c, radius: 6.5, startAngle: 0, endAngle: 360)
            track.lineWidth = 2.5
            NSColor.tertiaryLabelColor.setStroke()
            track.stroke()
            let p = min(max(pct, 0), 100)
            if p > 0 {
                let arc = NSBezierPath()
                arc.appendArc(withCenter: c, radius: 6.5, startAngle: 90,
                              endAngle: 90 - 360 * CGFloat(p) / 100, clockwise: true)
                arc.lineWidth = 2.5
                arc.lineCapStyle = .round
                color.setStroke()
                arc.stroke()
            }
            return true
        }
    }

    // MARK: - Rendering (main thread only; no network)

    private var freshnessText: String {
        guard let t = lastSuccess else { return "No data yet" }
        let secs = Int(-t.timeIntervalSinceNow)
        if secs < 60 { return "Updated just now" }
        let m = secs / 60
        if m < 60 { return "Updated \(m)m ago" }
        return "Updated \(m / 60)h \(m % 60)m ago"
    }

    private func tokenText(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }

    private func activityItems(_ act: (todayTokens: Int, todayTurns: Int, weekTokens: Int, weekTurns: Int)) -> [NSMenuItem] {
        func turns(_ n: Int) -> String { n == 1 ? "1 turn" : "\(n) turns" }
        let theme = Theme.current
        let today = NSMenuItem()
        today.view = StatRowView(icon: "bolt.fill", name: "Today",
                                 value: "\(tokenText(act.todayTokens)) tok · \(turns(act.todayTurns))",
                                 color: theme.color(kind: "session", pct: 0))
        let week = NSMenuItem()
        week.view = StatRowView(icon: "calendar", name: "Last 7 days",
                                value: "\(tokenText(act.weekTokens)) tok · \(turns(act.weekTurns))",
                                color: theme.color(kind: "weekly_all", pct: 45))
        return [today, week]
    }

    private var headerSubtitle: String {
        if let plan = planName, !plan.isEmpty {
            return planTier != nil ? "\(plan.capitalized) plan · \(planTier!) · live"
                                   : "\(plan.capitalized) plan · live"
        }
        return "\(Provider.current.rawValue) · live"
    }

    private func authWarningItem() -> NSMenuItem? {
        let codex = Provider.current == .codex
        let text: String
        switch authState {
        case .expired: text = codex ? "⚠︎ Codex sign-in expired — run `codex` to re-login"
                                    : "⚠︎ Sign-in expired — open Claude Code to refresh"
        case .missing: text = codex ? "⚠︎ No Codex login — run `codex` and sign in"
                                    : "⚠︎ No Claude Code login — run `claude` and sign in"
        default: return nil
        }
        let it = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        it.isEnabled = false
        it.attributedTitle = NSAttributedString(string: text, attributes: [
            .foregroundColor: NSColor.systemOrange,
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
        ])
        return it
    }

    private func render() {
        let theme = Theme.current

        let glyph = Provider.current.glyph
        guard let limits = lastLimits else {
            let noDataTitle = (authState == .expired || authState == .missing) ? "\(glyph) ⚠︎" : "\(glyph) …"
            statusItem.button?.attributedTitle = NSAttributedString(string: noDataTitle,
                attributes: [.foregroundColor: NSColor.secondaryLabelColor])
            statusItem.button?.image = nil
            let menu = NSMenu()
            menu.delegate = self
            let h = NSMenuItem(); h.view = HeaderView(worst: 0, accent: theme.accent(worst: 0, worstKind: ""), themeSymbol: theme.symbol, title: Provider.current.appTitle, subtitle: headerSubtitle)
            menu.addItem(h)
            let s = NSMenuItem(); s.view = SepView(); menu.addItem(s)
            if let warn = authWarningItem() {
                menu.addItem(warn)
            } else {
                let msg = NSMenuItem(title: "Waiting for usage data…", action: nil, keyEquivalent: "")
                msg.isEnabled = false
                menu.addItem(msg)
                let info = NSMenuItem(title: "Endpoint busy (rate-limited) — retrying automatically", action: nil, keyEquivalent: "")
                info.isEnabled = false
                menu.addItem(info)
            }
            appendFooter(to: menu)
            statusItem.menu = menu
            freshItem = nil   // this menu has no freshness row
            return
        }

        var parts: [String] = []
        var worst = 0.0
        var worstKind = ""
        for l in limits {
            let p = (l["percent"] as? NSNumber)?.doubleValue ?? 0
            if p > worst { worst = p; worstKind = l["kind"] as? String ?? "" }
        }

        let menu = NSMenu()
        menu.delegate = self
        let headerItem = NSMenuItem()
        headerItem.view = HeaderView(worst: worst,
                                     accent: theme.accent(worst: worst, worstKind: worstKind),
                                     themeSymbol: theme.symbol,
                                     title: Provider.current.appTitle,
                                     subtitle: headerSubtitle)
        menu.addItem(headerItem)
        let sep0 = NSMenuItem(); sep0.view = SepView(); menu.addItem(sep0)

        if let warn = authWarningItem() { menu.addItem(warn) }

        if limits.isEmpty {
            // Codex Business/Enterprise seats report no rate-limit windows —
            // show token activity from the analytics endpoint instead.
            var title = "\(glyph) —"
            if let act = codexActivity {
                activityItems(act).forEach { menu.addItem($0) }
                title = "\(glyph) \(tokenText(act.todayTokens))"
            }
            let caption = "No personal rate limits — this plan meters usage at the workspace level"
            let info = NSMenuItem(title: caption, action: nil, keyEquivalent: "")
            info.isEnabled = false
            info.attributedTitle = NSAttributedString(string: caption, attributes: [
                .foregroundColor: NSColor.tertiaryLabelColor,
                .font: NSFont.systemFont(ofSize: 10.5),
            ])
            menu.addItem(info)
            appendFooter(to: menu)
            statusItem.menu = menu
            freshItem = nil
            statusItem.button?.attributedTitle = NSAttributedString(string: title,
                attributes: [.foregroundColor: NSColor.secondaryLabelColor,
                             .font: NSFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .semibold)])
            statusItem.button?.image = nil
            return
        }

        let layout = LayoutStyle.current
        var infos: [(kind: String, label: String, pct: Double, reset: String, active: Bool)] = []
        for l in limits {
            let kind = l["kind"] as? String ?? ""
            let pct = (l["percent"] as? NSNumber)?.doubleValue ?? 0
            var short = "\(Int(pct))%"
            var label = kind
            switch kind {
            case "session":
                short = "5h \(Int(pct))%"; label = "5-hour session"
            case "weekly_all":
                short = "wk \(Int(pct))%"; label = "Weekly · all models"
            case "weekly_scoped":
                let model = ((l["scope"] as? [String: Any])?["model"] as? [String: Any])?["display_name"] as? String ?? "scoped"
                short = "\(model.prefix(3)) \(Int(pct))%"; label = "Weekly · \(model)"
            default: break
            }
            if let overrideLabel = l["label"] as? String { label = overrideLabel }
            if let overrideShort = l["short"] as? String { short = overrideShort }
            parts.append(short)
            infos.append((kind, label, pct, resetsIn(l["resets_at"] as? String), l["is_active"] as? Bool == true))

            if layout == .classic {
                let item = NSMenuItem()
                item.view = RowView(icon: iconFor(kind), name: label, pct: pct,
                                    reset: resetsIn(l["resets_at"] as? String),
                                    active: (l["is_active"] as? Bool == true),
                                    color: theme.color(kind: kind, pct: pct))
                menu.addItem(item)
            }
        }

        switch layout {
        case .classic:
            break
        case .rings:
            let gauges = infos.map { i -> (label: String, reset: String, pct: Double, color: NSColor) in
                let short: String
                if i.kind == "session" { short = "5h" }
                else if let tail = i.label.split(separator: "·").last {
                    short = tail.trimmingCharacters(in: .whitespaces)
                } else { short = i.label }
                return (label: short,
                        reset: i.reset.replacingOccurrences(of: "resets in ", with: ""),
                        pct: i.pct,
                        color: theme.color(kind: i.kind, pct: i.pct))
            }
            let item = NSMenuItem()
            item.view = RingsRowView(gauges: gauges)
            menu.addItem(item)
        case .segments:
            for i in infos {
                let item = NSMenuItem()
                item.view = SegRowView(icon: iconFor(i.kind), name: i.label, pct: i.pct,
                                       reset: i.reset, active: i.active,
                                       color: theme.color(kind: i.kind, pct: i.pct))
                menu.addItem(item)
            }
        case .trend:
            for i in infos {
                let item = NSMenuItem()
                item.view = TrendRowView(icon: iconFor(i.kind), name: i.label, pct: i.pct,
                                         caption: forecastCaption(kind: i.kind, pct: i.pct, reset: i.reset),
                                         active: i.active,
                                         color: theme.color(kind: i.kind, pct: i.pct),
                                         points: UsageHistory.series(kind: i.kind, hours: i.kind == "session" ? 5 : 72))
                menu.addItem(item)
            }
        }

        if Provider.current == .codex, let act = codexActivity {
            activityItems(act).forEach { menu.addItem($0) }
        }

        let fresh = NSMenuItem(title: freshnessText, action: nil, keyEquivalent: "")
        fresh.isEnabled = false
        fresh.attributedTitle = NSAttributedString(string: freshnessText, attributes: [
            .foregroundColor: NSColor.tertiaryLabelColor,
            .font: NSFont.systemFont(ofSize: 11),
        ])
        menu.addItem(fresh)
        freshItem = fresh

        appendFooter(to: menu)
        statusItem.menu = menu

        // Menu-bar title per the user's chosen style. Narrower styles help on
        // notched MacBooks, where a crowded menu bar silently hides wide items.
        let title: String
        var titleColor = theme.accent(worst: worst, worstKind: worstKind)
        switch BarStyle.current {
        case .full:
            title = "\(glyph) " + parts.joined(separator: " · ")
        case .compact:
            title = "\(glyph) \(Int(worst))%"
        case .session:
            if let s = limits.first(where: { ($0["kind"] as? String) == "session" }) {
                let p = (s["percent"] as? NSNumber)?.doubleValue ?? 0
                title = "\(glyph) 5h \(Int(p))%"
                titleColor = theme.color(kind: "session", pct: p)
            } else {
                title = "\(glyph) " + parts.joined(separator: " · ")
            }
        case .ring:
            title = ""   // the ring image below is the whole icon
        }
        // Stale data (token lapsed) gets a visible ⚠︎ and loses its color —
        // never let old numbers pass as live.
        var finalTitle = title
        if authState == .expired || authState == .missing {
            finalTitle = title + " ⚠︎"
            titleColor = .secondaryLabelColor
        }
        statusItem.button?.attributedTitle = NSAttributedString(string: finalTitle, attributes: [
            .foregroundColor: titleColor,
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .semibold),
        ])
        if BarStyle.current == .ring {
            statusItem.button?.image = ringImage(pct: worst, color: titleColor)
            statusItem.button?.imagePosition = finalTitle.isEmpty ? .imageOnly : .imageLeading
        } else {
            statusItem.button?.image = nil
        }
    }

    private func appendFooter(to menu: NSMenu) {
        let sep = NSMenuItem(); sep.view = SepView(); menu.addItem(sep)

        let providerItem = NSMenuItem(title: "Provider", action: nil, keyEquivalent: "")
        providerItem.image = NSImage(systemSymbolName: "person.2", accessibilityDescription: nil)
        let providerMenu = NSMenu()
        for p in Provider.allCases {
            let it = NSMenuItem(title: p.rawValue, action: #selector(selectProvider(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = p.rawValue
            it.state = (p == Provider.current) ? .on : .off
            providerMenu.addItem(it)
        }
        providerItem.submenu = providerMenu
        menu.addItem(providerItem)

        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeItem.image = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: nil)
        let themeMenu = NSMenu()
        for t in Theme.allCases {
            let it = NSMenuItem(title: t.rawValue, action: #selector(selectTheme(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = t.rawValue
            it.state = (t == Theme.current) ? .on : .off
            themeMenu.addItem(it)
        }
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        let styleItem = NSMenuItem(title: "Menu Bar Style", action: nil, keyEquivalent: "")
        styleItem.image = NSImage(systemSymbolName: "arrow.left.and.right", accessibilityDescription: nil)
        let styleMenu = NSMenu()
        for s in BarStyle.allCases {
            let it = NSMenuItem(title: s.rawValue, action: #selector(selectStyle(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = s.rawValue
            it.state = (s == BarStyle.current) ? .on : .off
            styleMenu.addItem(it)
        }
        styleItem.submenu = styleMenu
        menu.addItem(styleItem)

        let layoutItem = NSMenuItem(title: "Layout", action: nil, keyEquivalent: "")
        layoutItem.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil)
        let layoutMenu = NSMenu()
        for s in LayoutStyle.allCases {
            let it = NSMenuItem(title: s.rawValue, action: #selector(selectLayout(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = s.rawValue
            it.state = (s == LayoutStyle.current) ? .on : .off
            layoutMenu.addItem(it)
        }
        layoutItem.submenu = layoutMenu
        menu.addItem(layoutItem)

        let refreshMenuItem = NSMenuItem(title: "Auto Refresh", action: nil, keyEquivalent: "")
        refreshMenuItem.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
        let rMenu = NSMenu()
        for mins in [1, 2, 5, 10, 15, 30, 60] {
            let it = NSMenuItem(title: "\(mins) min", action: #selector(selectRefresh(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = mins
            it.state = (mins == AppDelegate.refreshMinutes) ? .on : .off
            rMenu.addItem(it)
        }
        refreshMenuItem.submenu = rMenu
        menu.addItem(refreshMenuItem)

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = loginEnabled ? .on : .off
        login.image = NSImage(systemSymbolName: "power.circle", accessibilityDescription: nil)
        menu.addItem(login)

        let sep2 = NSMenuItem(); sep2.view = SepView(); menu.addItem(sep2)

        let refreshItem = NSMenuItem(title: "Refresh now", action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self
        refreshItem.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        menu.addItem(refreshItem)

        let usageItem = NSMenuItem(title: Provider.current == .codex ? "Open Codex usage" : "Open claude.ai usage",
                                   action: #selector(openUsage), keyEquivalent: "")
        usageItem.target = self
        usageItem.image = NSImage(systemSymbolName: "safari", accessibilityDescription: nil)
        menu.addItem(usageItem)

        if updating {
            let it = NSMenuItem(title: "Updating… (rebuilding via brew)", action: nil, keyEquivalent: "")
            it.isEnabled = false
            it.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)
            menu.addItem(it)
        } else if let v = latestVersion {
            let it = NSMenuItem(title: "Update to \(v) available…", action: #selector(installUpdate), keyEquivalent: "")
            it.target = self
            it.image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: nil)
            menu.addItem(it)
        } else {
            let it = NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdatesClicked), keyEquivalent: "")
            it.target = self
            it.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: nil)
            menu.addItem(it)
        }

        let aboutItem = NSMenuItem(title: "About (unofficial)", action: #selector(about), keyEquivalent: "")
        aboutItem.target = self
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(quitItem)
    }

    // MARK: - Launch at Login (SMAppService — uses modern Login Items, not the EDR-locked LaunchAgents dir)

    private var loginEnabled: Bool {
        if #available(macOS 13.0, *) { return SMAppService.mainApp.status == .enabled }
        return false
    }
    @objc private func toggleLogin() {
        guard #available(macOS 13.0, *) else { return }
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let a = NSAlert()
            a.messageText = "Couldn’t change Launch at Login"
            a.informativeText = "\(error.localizedDescription)\n\nOn managed/corporate Macs this may be restricted by device policy."
            a.runModal()
        }
        render()
    }

    // MARK: - Updates (GitHub releases check + one-click `brew` upgrade)
    //
    // No Sparkle, no downloaded binaries (unsigned apps would hit Gatekeeper).
    // Homebrew is the update channel: we compare our version against the latest
    // GitHub release tag, and on demand run `brew update && brew reinstall`,
    // which rebuilds from source locally, then relaunch.

    private func semverIsNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").map { Int($0) ?? 0 }
        let l = local.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(r.count, l.count) {
            let a = i < r.count ? r[i] : 0
            let b = i < l.count ? l[i] : 0
            if a != b { return a > b }
        }
        return false
    }

    private func checkForUpdates(interactive: Bool = false) {
        lastUpdateCheck = Date()
        var req = URLRequest(url: URL(string: "https://api.github.com/repos/sagar-18/claude-usage-bar/releases/latest")!)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 10
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            var remote: String?
            if let data = data,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tag = obj["tag_name"] as? String {
                remote = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            }
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let remote = remote, self.semverIsNewer(remote, than: Self.currentVersion) {
                    self.latestVersion = remote
                    self.render()
                    if interactive { self.installUpdate() }
                } else if interactive {
                    let a = NSAlert()
                    if remote == nil {
                        a.messageText = "Couldn't check for updates"
                        a.informativeText = "Could not reach GitHub. Please try again later."
                    } else {
                        a.messageText = "You're up to date"
                        a.informativeText = "Claude Usage Bar \(Self.currentVersion) is the latest version."
                    }
                    a.runModal()
                }
            }
        }.resume()
    }
    @objc private func checkForUpdatesClicked() { checkForUpdates(interactive: true) }

    private var brewPath: String? {
        ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    @objc private func installUpdate() {
        guard let v = latestVersion, !updating else { return }
        guard let brew = brewPath else {
            // Not a brew install (or brew missing) — send them to the release page.
            NSWorkspace.shared.open(URL(string: "https://github.com/sagar-18/claude-usage-bar/releases/latest")!)
            return
        }
        let a = NSAlert()
        a.messageText = "Update to \(v)?"
        a.informativeText = "This runs `brew update && brew reinstall claude-usage-bar` in the background (rebuilds from source, may take a minute) and relaunches the app when done."
        a.addButton(withTitle: "Update")
        a.addButton(withTitle: "Later")
        guard a.runModal() == .alertFirstButtonReturn else { return }

        updating = true
        render()
        let prefix = (brew as NSString).deletingLastPathComponent          // …/bin
        let appPath = ((prefix as NSString).deletingLastPathComponent as NSString)
            .appendingPathComponent("opt/claude-usage-bar/ClaudeUsageBar.app")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = ["-c", "\"\(brew)\" update >/dev/null 2>&1; \"\(brew)\" reinstall claude-usage-bar 2>&1"]
            let out = Pipe()
            task.standardOutput = out
            task.standardError = out
            do { try task.run() } catch {
                DispatchQueue.main.async { self?.updateFailed("Couldn't run brew: \(error.localizedDescription)") }
                return
            }
            let output = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            task.waitUntilExit()
            DispatchQueue.main.async {
                guard let self = self else { return }
                if task.terminationStatus == 0 {
                    // Relaunch the freshly built app after we exit.
                    let relaunch = Process()
                    relaunch.executableURL = URL(fileURLWithPath: "/bin/bash")
                    relaunch.arguments = ["-c", "sleep 1; open \"\(appPath)\""]
                    try? relaunch.run()
                    NSApplication.shared.terminate(nil)
                } else {
                    self.updateFailed(String(output.suffix(500)))
                }
            }
        }
    }

    private func updateFailed(_ detail: String) {
        updating = false
        render()
        let a = NSAlert()
        a.messageText = "Update failed"
        a.informativeText = "brew reinstall did not succeed. You can update manually:\n\nbrew update && brew reinstall claude-usage-bar\n\n\(detail)"
        a.runModal()
    }

    @objc private func selectTheme(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let t = Theme(rawValue: raw) {
            Theme.current = t
            render()   // no network — just recolor from last data
        }
    }
    @objc private func selectProvider(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let p = Provider(rawValue: raw), p != Provider.current else { return }
        Provider.current = p
        // The cached data belongs to the other provider — drop it and refetch.
        lastLimits = nil
        lastSuccess = nil
        authState = .unknown
        planName = nil
        planTier = nil
        codexActivity = nil
        render()
        refreshNow()
    }
    @objc private func selectLayout(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let s = LayoutStyle(rawValue: raw) {
            LayoutStyle.current = s
            render()   // no network — rebuild the menu from cached data
        }
    }
    @objc private func selectStyle(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let s = BarStyle(rawValue: raw) {
            BarStyle.current = s
            render()   // no network — just re-render the title from last data
        }
    }
    @objc private func selectRefresh(_ sender: NSMenuItem) {
        if let mins = sender.representedObject as? Int {
            AppDelegate.refreshMinutes = mins
            backoff = 0
            scheduleNext(normalInterval)   // apply new cadence without an extra fetch
            render()                       // update the checkmark
        }
    }
    @objc private func openUsage() {
        NSWorkspace.shared.open(URL(string: Provider.current.usageURL)!)
    }
    @objc private func about() {
        let a = NSAlert()
        a.messageText = "Claude Usage Bar \(Self.currentVersion)"
        a.informativeText = """
        Unofficial menu-bar usage tracker. Not affiliated with, or endorsed by, Anthropic.

        It reads YOUR usage from YOUR local Claude Code login token and calls an undocumented endpoint that may change at any time.

        USE AT YOUR OWN RISK. Provided “as is”, with no warranty of any kind. The author is NOT responsible or liable for anything that happens to your Claude / Anthropic account — including rate limiting, throttling, suspension, or termination — arising from use of this app. By using it, you accept full responsibility.

        MIT licensed · github.com/sagar-18/claude-usage-bar
        """
        a.addButton(withTitle: "OK")
        a.addButton(withTitle: "Open GitHub")
        if a.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.open(URL(string: "https://github.com/sagar-18/claude-usage-bar")!)
        }
    }
    @objc private func quit() { NSApplication.shared.terminate(nil) }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
