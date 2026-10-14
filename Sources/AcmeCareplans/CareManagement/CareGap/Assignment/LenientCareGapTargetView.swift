import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient care gap target.
    final class LenientCareGapTargetView {
        var code: String
        var labelText: String
        var maximum: String
        var checksum: String
        var weight: String
        var clinicianID: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, labelText: String, maximum: String, checksum: String, weight: String, clinicianID: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.maximum = maximum
            self.checksum = checksum
            self.weight = weight
            self.clinicianID = clinicianID
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCareGapTargetView(_ item: LenientCareGapTarget) -> LenientCareGapTargetView {
        return LenientCareGapTargetView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            weight: String(format: "%.2f", item.weight),
            clinicianID: item.clinicianID,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCareGapTargetViews(_ items: [LenientCareGapTarget]) -> [LenientCareGapTargetView] {
        var views: [LenientCareGapTargetView] = []
        for item in items {
            views.append(toLenientCareGapTargetView(item))
        }
        return views
    }

    static func sumLenientCareGapTargetView(_ view: LenientCareGapTargetView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedMaximum + parsedWeight + Double(parsedExpiresAt)
    }
}
