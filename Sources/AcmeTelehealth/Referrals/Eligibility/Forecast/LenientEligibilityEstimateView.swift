import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient eligibility estimate.
    final class LenientEligibilityEstimateView {
        var code: String
        var nameText: String
        var diagnosisCodeText: String
        var revision: String
        var summaryText: String
        var ward: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, nameText: String, diagnosisCodeText: String, revision: String, summaryText: String, ward: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.diagnosisCodeText = diagnosisCodeText
            self.revision = revision
            self.summaryText = summaryText
            self.ward = ward
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientEligibilityEstimateView(_ item: LenientEligibilityEstimate) -> LenientEligibilityEstimateView {
        return LenientEligibilityEstimateView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            diagnosisCodeText: item.diagnosisCode,
            revision: String(item.revision),
            summaryText: item.summary,
            ward: item.ward,
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientEligibilityEstimateViews(_ items: [LenientEligibilityEstimate]) -> [LenientEligibilityEstimateView] {
        var views: [LenientEligibilityEstimateView] = []
        for item in items {
            views.append(toLenientEligibilityEstimateView(item))
        }
        return views
    }

    static func sumLenientEligibilityEstimateView(_ view: LenientEligibilityEstimateView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedRevision) + parsedFloorValue
    }
}
