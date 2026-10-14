import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime snapshot.
    final class OvertimeSnapshotView {
        var codeText: String
        var label: String
        var encounterID: String
        var segment: String
        var allergy: String
        var phone: String
        var graceDays: String
        var budget: String
        var statusLabel: String

        init(codeText: String, label: String, encounterID: String, segment: String, allergy: String, phone: String, graceDays: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.encounterID = encounterID
            self.segment = segment
            self.allergy = allergy
            self.phone = phone
            self.graceDays = graceDays
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeSnapshotView(_ item: OvertimeSnapshot) -> OvertimeSnapshotView {
        return OvertimeSnapshotView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 120),
            encounterID: item.encounterID,
            segment: Kit.Text.truncate(item.segment, limit: 80),
            allergy: item.allergy,
            phone: item.phone,
            graceDays: String(item.graceDays),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeSnapshotViews(_ items: [OvertimeSnapshot]) -> [OvertimeSnapshotView] {
        var views: [OvertimeSnapshotView] = []
        for item in items {
            views.append(toOvertimeSnapshotView(item))
        }
        return views
    }

    static func sumOvertimeSnapshotView(_ view: OvertimeSnapshotView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedGraceDays) + parsedBudget
    }
}
