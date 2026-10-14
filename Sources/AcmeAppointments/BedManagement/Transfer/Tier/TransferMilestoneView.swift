import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer milestone.
    final class TransferMilestoneView {
        var code: String
        var label: String
        var notes: String
        var active: String
        var ratio: String
        var diagnosisCodeText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, label: String, notes: String, active: String, ratio: String, diagnosisCodeText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.notes = notes
            self.active = active
            self.ratio = ratio
            self.diagnosisCodeText = diagnosisCodeText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toTransferMilestoneView(_ item: TransferMilestone) -> TransferMilestoneView {
        return TransferMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            notes: item.notes,
            active: "\(item.active)",
            ratio: String(format: "%.2f", item.ratio),
            diagnosisCodeText: item.diagnosisCode,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferMilestoneViews(_ items: [TransferMilestone]) -> [TransferMilestoneView] {
        var views: [TransferMilestoneView] = []
        for item in items {
            views.append(toTransferMilestoneView(item))
        }
        return views
    }

    static func sumTransferMilestoneView(_ view: TransferMilestoneView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedRatio + Double(parsedEndsAt)
    }
}
