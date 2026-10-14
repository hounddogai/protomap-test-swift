import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap adjustment.
    final class CareGapAdjustmentView {
        var code: String
        var labelText: String
        var source: String
        var version: String
        var currency: String
        var statusLabel: String

        init(code: String, labelText: String, source: String, version: String, currency: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.source = source
            self.version = version
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapAdjustmentView(_ item: CareGapAdjustment) -> CareGapAdjustmentView {
        return CareGapAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            source: item.source,
            version: String(item.version),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapAdjustmentViews(_ items: [CareGapAdjustment]) -> [CareGapAdjustmentView] {
        var views: [CareGapAdjustmentView] = []
        for item in items {
            views.append(toCareGapAdjustmentView(item))
        }
        return views
    }

    static func sumCareGapAdjustmentView(_ view: CareGapAdjustmentView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
