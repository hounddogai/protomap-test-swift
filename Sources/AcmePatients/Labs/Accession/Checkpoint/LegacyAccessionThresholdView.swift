import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy accession threshold.
    final class LegacyAccessionThresholdView {
        var code: String
        var label: String
        var createdAtText: String
        var clinicianIDText: String
        var patientRef: String
        var externalRef: String
        var pinned: String
        var copay: String
        var active: String
        var discount: String
        var statusLabel: String

        init(code: String, label: String, createdAtText: String, clinicianIDText: String, patientRef: String, externalRef: String, pinned: String, copay: String, active: String, discount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAtText = createdAtText
            self.clinicianIDText = clinicianIDText
            self.patientRef = patientRef
            self.externalRef = externalRef
            self.pinned = pinned
            self.copay = copay
            self.active = active
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAccessionThresholdView(_ item: LegacyAccessionThreshold) -> LegacyAccessionThresholdView {
        return LegacyAccessionThresholdView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            createdAtText: String(item.createdAt),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 120),
            patientRef: item.patientRef,
            externalRef: item.externalRef,
            pinned: "\(item.pinned)",
            copay: String(format: "%.2f", item.copay),
            active: "\(item.active)",
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAccessionThresholdViews(_ items: [LegacyAccessionThreshold]) -> [LegacyAccessionThresholdView] {
        var views: [LegacyAccessionThresholdView] = []
        for item in items {
            views.append(toLegacyAccessionThresholdView(item))
        }
        return views
    }

    static func sumLegacyAccessionThresholdView(_ view: LegacyAccessionThresholdView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedCreatedAt) + parsedCopay + parsedDiscount
    }
}
