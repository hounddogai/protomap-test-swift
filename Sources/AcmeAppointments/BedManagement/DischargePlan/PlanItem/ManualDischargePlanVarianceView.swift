import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual discharge plan variance.
    final class ManualDischargePlanVarianceView {
        var code: String
        var labelText: String
        var expiresAt: String
        var segment: String
        var categoryText: String
        var maximum: String
        var quantityText: String
        var channelText: String
        var bedText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, labelText: String, expiresAt: String, segment: String, categoryText: String, maximum: String, quantityText: String, channelText: String, bedText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.expiresAt = expiresAt
            self.segment = segment
            self.categoryText = categoryText
            self.maximum = maximum
            self.quantityText = quantityText
            self.channelText = channelText
            self.bedText = bedText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toManualDischargePlanVarianceView(_ item: ManualDischargePlanVariance) -> ManualDischargePlanVarianceView {
        return ManualDischargePlanVarianceView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            expiresAt: String(item.expiresAt),
            segment: Kit.Text.truncate(item.segment, limit: 40),
            categoryText: item.category,
            maximum: String(format: "%.2f", item.maximum),
            quantityText: String(item.quantity),
            channelText: item.channel,
            bedText: item.bed,
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualDischargePlanVarianceViews(_ items: [ManualDischargePlanVariance]) -> [ManualDischargePlanVarianceView] {
        var views: [ManualDischargePlanVarianceView] = []
        for item in items {
            views.append(toManualDischargePlanVarianceView(item))
        }
        return views
    }

    static func sumManualDischargePlanVarianceView(_ view: ManualDischargePlanVarianceView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedExpiresAt) + parsedMaximum + Double(parsedQuantity)
    }
}
