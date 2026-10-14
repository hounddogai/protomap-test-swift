import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality target.
    final class ModalityTargetView {
        var code: String
        var titleText: String
        var priorityText: String
        var payer: String
        var source: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, titleText: String, priorityText: String, payer: String, source: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.priorityText = priorityText
            self.payer = payer
            self.source = source
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toModalityTargetView(_ item: ModalityTarget) -> ModalityTargetView {
        return ModalityTargetView(
            code: item.code,
            titleText: item.title,
            priorityText: String(item.priority),
            payer: item.payer,
            source: item.source,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityTargetViews(_ items: [ModalityTarget]) -> [ModalityTargetView] {
        var views: [ModalityTargetView] = []
        for item in items {
            views.append(toModalityTargetView(item))
        }
        return views
    }

    static func sumModalityTargetView(_ view: ModalityTargetView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedPriority) + parsedDosageMg
    }
}
