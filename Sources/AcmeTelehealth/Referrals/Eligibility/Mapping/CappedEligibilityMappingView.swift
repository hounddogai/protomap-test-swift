import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped eligibility mapping.
    final class CappedEligibilityMappingView {
        var code: String
        var title: String
        var ward: String
        var unit: String
        var ratio: String
        var clinicianIDText: String
        var sequence: String
        var statusLabel: String

        init(code: String, title: String, ward: String, unit: String, ratio: String, clinicianIDText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ward = ward
            self.unit = unit
            self.ratio = ratio
            self.clinicianIDText = clinicianIDText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toCappedEligibilityMappingView(_ item: CappedEligibilityMapping) -> CappedEligibilityMappingView {
        return CappedEligibilityMappingView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            ward: item.ward,
            unit: item.unit,
            ratio: String(format: "%.2f", item.ratio),
            clinicianIDText: item.clinicianID,
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedEligibilityMappingViews(_ items: [CappedEligibilityMapping]) -> [CappedEligibilityMappingView] {
        var views: [CappedEligibilityMappingView] = []
        for item in items {
            views.append(toCappedEligibilityMappingView(item))
        }
        return views
    }

    static func sumCappedEligibilityMappingView(_ view: CappedEligibilityMappingView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedRatio + Double(parsedSequence)
    }
}
