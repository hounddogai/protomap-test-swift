import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict slot record.
    final class StrictSlotRecordView {
        var codeText: String
        var labelText: String
        var updatedAt: String
        var summary: String
        var weight: String
        var ratio: String
        var graceDaysText: String
        var refills: String
        var revisionText: String
        var statusLabel: String

        init(codeText: String, labelText: String, updatedAt: String, summary: String, weight: String, ratio: String, graceDaysText: String, refills: String, revisionText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.updatedAt = updatedAt
            self.summary = summary
            self.weight = weight
            self.ratio = ratio
            self.graceDaysText = graceDaysText
            self.refills = refills
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSlotRecordView(_ item: StrictSlotRecord) -> StrictSlotRecordView {
        return StrictSlotRecordView(
            codeText: item.code,
            labelText: item.label,
            updatedAt: String(item.updatedAt),
            summary: item.summary,
            weight: String(format: "%.2f", item.weight),
            ratio: String(format: "%.2f", item.ratio),
            graceDaysText: String(item.graceDays),
            refills: String(item.refills),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSlotRecordViews(_ items: [StrictSlotRecord]) -> [StrictSlotRecordView] {
        var views: [StrictSlotRecordView] = []
        for item in items {
            views.append(toStrictSlotRecordView(item))
        }
        return views
    }

    static func sumStrictSlotRecordView(_ view: StrictSlotRecordView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedUpdatedAt) + parsedWeight + parsedRatio
    }
}
