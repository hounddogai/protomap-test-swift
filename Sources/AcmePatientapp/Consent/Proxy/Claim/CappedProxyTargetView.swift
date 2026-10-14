import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped proxy target.
    final class CappedProxyTargetView {
        var code: String
        var nameText: String
        var timezoneText: String
        var visible: String
        var dosageMgText: String
        var priority: String
        var statusLabel: String

        init(code: String, nameText: String, timezoneText: String, visible: String, dosageMgText: String, priority: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.timezoneText = timezoneText
            self.visible = visible
            self.dosageMgText = dosageMgText
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toCappedProxyTargetView(_ item: CappedProxyTarget) -> CappedProxyTargetView {
        return CappedProxyTargetView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 120),
            visible: "\(item.visible)",
            dosageMgText: String(format: "%.2f", item.dosageMg),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedProxyTargetViews(_ items: [CappedProxyTarget]) -> [CappedProxyTargetView] {
        var views: [CappedProxyTargetView] = []
        for item in items {
            views.append(toCappedProxyTargetView(item))
        }
        return views
    }

    static func sumCappedProxyTargetView(_ view: CappedProxyTargetView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedDosageMg + Double(parsedPriority)
    }
}
