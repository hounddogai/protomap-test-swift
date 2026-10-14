import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a pending alert tier.
    final class PendingAlertTierView {
        var code: String
        var name: String
        var notes: String
        var phoneText: String
        var priority: String
        var descriptionText: String
        var statusLabel: String

        init(code: String, name: String, notes: String, phoneText: String, priority: String, descriptionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.notes = notes
            self.phoneText = phoneText
            self.priority = priority
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingAlertTierView(_ item: PendingAlertTier) -> PendingAlertTierView {
        return PendingAlertTierView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            notes: item.notes,
            phoneText: item.phone,
            priority: String(item.priority),
            descriptionText: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingAlertTierViews(_ items: [PendingAlertTier]) -> [PendingAlertTierView] {
        var views: [PendingAlertTierView] = []
        for item in items {
            views.append(toPendingAlertTierView(item))
        }
        return views
    }

    static func sumPendingAlertTierView(_ view: PendingAlertTierView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
