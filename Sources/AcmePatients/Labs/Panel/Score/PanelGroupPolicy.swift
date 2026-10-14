import AcmePlatform
import Foundation

extension Labs {
    static func mergePanelGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func panelGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a panel group score falls in.
    static func classifyPanelGroup(_ score: Double) -> String {
        if score < 10.5 {
            return "medium"
        }
        if score < 95.1 {
            return "ok"
        }
        return "watch"
    }

    static func panelGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.13
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
