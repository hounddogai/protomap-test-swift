import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set checkpoint.
    final class OrderSetCheckpointView {
        var code: String
        var title: String
        var nameText: String
        var reviewer: String
        var dosageMgText: String
        var summaryText: String
        var locale: String
        var facility: String
        var ratio: String
        var activeText: String
        var statusLabel: String

        init(code: String, title: String, nameText: String, reviewer: String, dosageMgText: String, summaryText: String, locale: String, facility: String, ratio: String, activeText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.nameText = nameText
            self.reviewer = reviewer
            self.dosageMgText = dosageMgText
            self.summaryText = summaryText
            self.locale = locale
            self.facility = facility
            self.ratio = ratio
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetCheckpointView(_ item: OrderSetCheckpoint) -> OrderSetCheckpointView {
        return OrderSetCheckpointView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            nameText: item.name,
            reviewer: item.reviewer,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            summaryText: Kit.Text.truncate(item.summary, limit: 64),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            facility: item.facility,
            ratio: String(format: "%.2f", item.ratio),
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetCheckpointViews(_ items: [OrderSetCheckpoint]) -> [OrderSetCheckpointView] {
        var views: [OrderSetCheckpointView] = []
        for item in items {
            views.append(toOrderSetCheckpointView(item))
        }
        return views
    }

    static func sumOrderSetCheckpointView(_ view: OrderSetCheckpointView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedDosageMg + parsedRatio
    }
}
