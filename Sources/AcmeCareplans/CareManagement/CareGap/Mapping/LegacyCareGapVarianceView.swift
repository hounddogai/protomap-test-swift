import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy care gap variance.
    final class LegacyCareGapVarianceView {
        var code: String
        var name: String
        var acuity: String
        var checksum: String
        var regionText: String
        var statusLabel: String

        init(code: String, name: String, acuity: String, checksum: String, regionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.checksum = checksum
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCareGapVarianceView(_ item: LegacyCareGapVariance) -> LegacyCareGapVarianceView {
        return LegacyCareGapVarianceView(
            code: item.code,
            name: item.name,
            acuity: String(item.acuity),
            checksum: item.checksum,
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCareGapVarianceViews(_ items: [LegacyCareGapVariance]) -> [LegacyCareGapVarianceView] {
        var views: [LegacyCareGapVarianceView] = []
        for item in items {
            views.append(toLegacyCareGapVarianceView(item))
        }
        return views
    }

    static func sumLegacyCareGapVarianceView(_ view: LegacyCareGapVarianceView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
