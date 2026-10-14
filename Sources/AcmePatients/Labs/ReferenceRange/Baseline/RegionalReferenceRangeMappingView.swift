import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional reference range mapping.
    final class RegionalReferenceRangeMappingView {
        var codeText: String
        var name: String
        var procedureCode: String
        var threshold: String
        var copay: String
        var acuityText: String
        var statusLabel: String

        init(codeText: String, name: String, procedureCode: String, threshold: String, copay: String, acuityText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.copay = copay
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalReferenceRangeMappingView(_ item: RegionalReferenceRangeMapping) -> RegionalReferenceRangeMappingView {
        return RegionalReferenceRangeMappingView(
            codeText: item.code,
            name: item.name,
            procedureCode: item.procedureCode,
            threshold: String(format: "%.2f", item.threshold),
            copay: String(format: "%.2f", item.copay),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalReferenceRangeMappingViews(_ items: [RegionalReferenceRangeMapping]) -> [RegionalReferenceRangeMappingView] {
        var views: [RegionalReferenceRangeMappingView] = []
        for item in items {
            views.append(toRegionalReferenceRangeMappingView(item))
        }
        return views
    }

    static func sumRegionalReferenceRangeMappingView(_ view: RegionalReferenceRangeMappingView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedThreshold + parsedCopay + Double(parsedAcuity)
    }
}
