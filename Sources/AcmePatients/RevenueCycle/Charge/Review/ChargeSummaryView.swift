import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge summary.
    final class ChargeSummaryView {
        var code: String
        var name: String
        var archivedText: String
        var bed: String
        var localeText: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, name: String, archivedText: String, bed: String, localeText: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archivedText = archivedText
            self.bed = bed
            self.localeText = localeText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toChargeSummaryView(_ item: ChargeSummary) -> ChargeSummaryView {
        return ChargeSummaryView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            archivedText: "\(item.archived)",
            bed: Kit.Text.truncate(item.bed, limit: 40),
            localeText: item.locale,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeSummaryViews(_ items: [ChargeSummary]) -> [ChargeSummaryView] {
        var views: [ChargeSummaryView] = []
        for item in items {
            views.append(toChargeSummaryView(item))
        }
        return views
    }

    static func sumChargeSummaryView(_ view: ChargeSummaryView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
