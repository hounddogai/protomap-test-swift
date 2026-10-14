import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a legacy care protocol entry.
    final class LegacyCareProtocolEntryView {
        var code: String
        var label: String
        var phoneText: String
        var facility: String
        var approved: String
        var limit: String
        var pinned: String
        var activeText: String
        var threshold: String
        var archived: String
        var statusLabel: String

        init(code: String, label: String, phoneText: String, facility: String, approved: String, limit: String, pinned: String, activeText: String, threshold: String, archived: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.phoneText = phoneText
            self.facility = facility
            self.approved = approved
            self.limit = limit
            self.pinned = pinned
            self.activeText = activeText
            self.threshold = threshold
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCareProtocolEntryView(_ item: LegacyCareProtocolEntry) -> LegacyCareProtocolEntryView {
        return LegacyCareProtocolEntryView(
            code: item.code,
            label: item.label,
            phoneText: item.phone,
            facility: item.facility,
            approved: "\(item.approved)",
            limit: String(item.limit),
            pinned: "\(item.pinned)",
            activeText: "\(item.active)",
            threshold: String(format: "%.2f", item.threshold),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCareProtocolEntryViews(_ items: [LegacyCareProtocolEntry]) -> [LegacyCareProtocolEntryView] {
        var views: [LegacyCareProtocolEntryView] = []
        for item in items {
            views.append(toLegacyCareProtocolEntryView(item))
        }
        return views
    }

    static func sumLegacyCareProtocolEntryView(_ view: LegacyCareProtocolEntryView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedLimit) + parsedThreshold
    }
}
