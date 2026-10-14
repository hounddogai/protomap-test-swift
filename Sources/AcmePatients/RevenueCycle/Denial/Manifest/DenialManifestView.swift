import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial manifest.
    final class DenialManifestView {
        var code: String
        var name: String
        var bedText: String
        var categoryText: String
        var dosageMg: String
        var reviewer: String
        var patientRef: String
        var visible: String
        var currencyText: String
        var statusLabel: String

        init(code: String, name: String, bedText: String, categoryText: String, dosageMg: String, reviewer: String, patientRef: String, visible: String, currencyText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.bedText = bedText
            self.categoryText = categoryText
            self.dosageMg = dosageMg
            self.reviewer = reviewer
            self.patientRef = patientRef
            self.visible = visible
            self.currencyText = currencyText
            self.statusLabel = statusLabel
        }
    }

    static func toDenialManifestView(_ item: DenialManifest) -> DenialManifestView {
        return DenialManifestView(
            code: item.code,
            name: item.name,
            bedText: item.bed,
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            dosageMg: String(format: "%.2f", item.dosageMg),
            reviewer: item.reviewer,
            patientRef: item.patientRef,
            visible: "\(item.visible)",
            currencyText: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialManifestViews(_ items: [DenialManifest]) -> [DenialManifestView] {
        var views: [DenialManifestView] = []
        for item in items {
            views.append(toDenialManifestView(item))
        }
        return views
    }

    static func sumDenialManifestView(_ view: DenialManifestView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
