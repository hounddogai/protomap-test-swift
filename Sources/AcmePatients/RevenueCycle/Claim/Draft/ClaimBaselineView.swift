import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim baseline.
    final class ClaimBaselineView {
        var code: String
        var label: String
        var bed: String
        var copay: String
        var clinicianID: String
        var specialty: String
        var statusLabel: String

        init(code: String, label: String, bed: String, copay: String, clinicianID: String, specialty: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.bed = bed
            self.copay = copay
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toClaimBaselineView(_ item: ClaimBaseline) -> ClaimBaselineView {
        return ClaimBaselineView(
            code: item.code,
            label: item.label,
            bed: item.bed,
            copay: String(format: "%.2f", item.copay),
            clinicianID: item.clinicianID,
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimBaselineViews(_ items: [ClaimBaseline]) -> [ClaimBaselineView] {
        var views: [ClaimBaselineView] = []
        for item in items {
            views.append(toClaimBaselineView(item))
        }
        return views
    }

    static func sumClaimBaselineView(_ view: ClaimBaselineView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
