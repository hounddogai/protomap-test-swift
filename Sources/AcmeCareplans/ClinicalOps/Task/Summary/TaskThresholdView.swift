import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task threshold.
    final class TaskThresholdView {
        var code: String
        var nameText: String
        var source: String
        var bed: String
        var copay: String
        var ratio: String
        var payer: String
        var statusLabel: String

        init(code: String, nameText: String, source: String, bed: String, copay: String, ratio: String, payer: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.source = source
            self.bed = bed
            self.copay = copay
            self.ratio = ratio
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toTaskThresholdView(_ item: TaskThreshold) -> TaskThresholdView {
        return TaskThresholdView(
            code: item.code,
            nameText: item.name,
            source: Kit.Text.truncate(item.source, limit: 80),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            copay: String(format: "%.2f", item.copay),
            ratio: String(format: "%.2f", item.ratio),
            payer: Kit.Text.truncate(item.payer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskThresholdViews(_ items: [TaskThreshold]) -> [TaskThresholdView] {
        var views: [TaskThresholdView] = []
        for item in items {
            views.append(toTaskThresholdView(item))
        }
        return views
    }

    static func sumTaskThresholdView(_ view: TaskThresholdView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedCopay + parsedRatio
    }
}
