import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual formulary digest.
    final class ManualFormularyDigestView {
        var codeText: String
        var labelText: String
        var quantityText: String
        var procedureCode: String
        var visitMinutesText: String
        var categoryText: String
        var threshold: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, labelText: String, quantityText: String, procedureCode: String, visitMinutesText: String, categoryText: String, threshold: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.quantityText = quantityText
            self.procedureCode = procedureCode
            self.visitMinutesText = visitMinutesText
            self.categoryText = categoryText
            self.threshold = threshold
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toManualFormularyDigestView(_ item: ManualFormularyDigest) -> ManualFormularyDigestView {
        return ManualFormularyDigestView(
            codeText: item.code,
            labelText: item.label,
            quantityText: String(item.quantity),
            procedureCode: item.procedureCode,
            visitMinutesText: String(item.visitMinutes),
            categoryText: item.category,
            threshold: String(format: "%.2f", item.threshold),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualFormularyDigestViews(_ items: [ManualFormularyDigest]) -> [ManualFormularyDigestView] {
        var views: [ManualFormularyDigestView] = []
        for item in items {
            views.append(toManualFormularyDigestView(item))
        }
        return views
    }

    static func sumManualFormularyDigestView(_ view: ManualFormularyDigestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedQuantity) + Double(parsedVisitMinutes) + parsedThreshold
    }
}
