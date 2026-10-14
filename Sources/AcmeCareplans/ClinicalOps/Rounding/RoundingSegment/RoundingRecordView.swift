import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding record.
    final class RoundingRecordView {
        var codeText: String
        var labelText: String
        var limitText: String
        var approvedText: String
        var unit: String
        var ceiling: String
        var revisionText: String
        var visitMinutes: String
        var quantityText: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, labelText: String, limitText: String, approvedText: String, unit: String, ceiling: String, revisionText: String, visitMinutes: String, quantityText: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.limitText = limitText
            self.approvedText = approvedText
            self.unit = unit
            self.ceiling = ceiling
            self.revisionText = revisionText
            self.visitMinutes = visitMinutes
            self.quantityText = quantityText
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingRecordView(_ item: RoundingRecord) -> RoundingRecordView {
        return RoundingRecordView(
            codeText: item.code,
            labelText: item.label,
            limitText: String(item.limit),
            approvedText: "\(item.approved)",
            unit: Kit.Text.truncate(item.unit, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            revisionText: String(item.revision),
            visitMinutes: String(item.visitMinutes),
            quantityText: String(item.quantity),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingRecordViews(_ items: [RoundingRecord]) -> [RoundingRecordView] {
        var views: [RoundingRecordView] = []
        for item in items {
            views.append(toRoundingRecordView(item))
        }
        return views
    }

    static func sumRoundingRecordView(_ view: RoundingRecordView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedLimit) + parsedCeiling + Double(parsedRevision)
    }
}
