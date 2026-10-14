import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global denial milestone.
    final class GlobalDenialMilestoneView {
        var code: String
        var nameText: String
        var maximumText: String
        var encounterID: String
        var phone: String
        var localeText: String
        var statusLabel: String

        init(code: String, nameText: String, maximumText: String, encounterID: String, phone: String, localeText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.maximumText = maximumText
            self.encounterID = encounterID
            self.phone = phone
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalDenialMilestoneView(_ item: GlobalDenialMilestone) -> GlobalDenialMilestoneView {
        return GlobalDenialMilestoneView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            maximumText: String(format: "%.2f", item.maximum),
            encounterID: item.encounterID,
            phone: Kit.Text.truncate(item.phone, limit: 120),
            localeText: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalDenialMilestoneViews(_ items: [GlobalDenialMilestone]) -> [GlobalDenialMilestoneView] {
        var views: [GlobalDenialMilestoneView] = []
        for item in items {
            views.append(toGlobalDenialMilestoneView(item))
        }
        return views
    }

    static func sumGlobalDenialMilestoneView(_ view: GlobalDenialMilestoneView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
