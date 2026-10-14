import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a tiered cleaning summary.
    final class TieredCleaningSummaryView {
        var codeText: String
        var titleText: String
        var pinned: String
        var dosageMg: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, titleText: String, pinned: String, dosageMg: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.pinned = pinned
            self.dosageMg = dosageMg
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCleaningSummaryView(_ item: TieredCleaningSummary) -> TieredCleaningSummaryView {
        return TieredCleaningSummaryView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            pinned: "\(item.pinned)",
            dosageMg: String(format: "%.2f", item.dosageMg),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCleaningSummaryViews(_ items: [TieredCleaningSummary]) -> [TieredCleaningSummaryView] {
        var views: [TieredCleaningSummaryView] = []
        for item in items {
            views.append(toTieredCleaningSummaryView(item))
        }
        return views
    }

    static func sumTieredCleaningSummaryView(_ view: TieredCleaningSummaryView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
