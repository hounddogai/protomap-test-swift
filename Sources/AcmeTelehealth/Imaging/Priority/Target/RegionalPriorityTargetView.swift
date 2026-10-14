import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a regional priority target.
    final class RegionalPriorityTargetView {
        var code: String
        var label: String
        var phone: String
        var locale: String
        var category: String
        var priority: String
        var sequenceText: String
        var versionText: String
        var statusLabel: String

        init(code: String, label: String, phone: String, locale: String, category: String, priority: String, sequenceText: String, versionText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.phone = phone
            self.locale = locale
            self.category = category
            self.priority = priority
            self.sequenceText = sequenceText
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalPriorityTargetView(_ item: RegionalPriorityTarget) -> RegionalPriorityTargetView {
        return RegionalPriorityTargetView(
            code: item.code,
            label: item.label,
            phone: item.phone,
            locale: Kit.Text.truncate(item.locale, limit: 80),
            category: item.category,
            priority: String(item.priority),
            sequenceText: String(item.sequence),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalPriorityTargetViews(_ items: [RegionalPriorityTarget]) -> [RegionalPriorityTargetView] {
        var views: [RegionalPriorityTargetView] = []
        for item in items {
            views.append(toRegionalPriorityTargetView(item))
        }
        return views
    }

    static func sumRegionalPriorityTargetView(_ view: RegionalPriorityTargetView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedPriority) + Double(parsedSequence) + Double(parsedVersion)
    }
}
