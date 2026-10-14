import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality score.
    final class ModalityScoreView {
        var code: String
        var titleText: String
        var category: String
        var patientRefText: String
        var capacityText: String
        var revision: String
        var discountText: String
        var sequence: String
        var statusLabel: String

        init(code: String, titleText: String, category: String, patientRefText: String, capacityText: String, revision: String, discountText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.category = category
            self.patientRefText = patientRefText
            self.capacityText = capacityText
            self.revision = revision
            self.discountText = discountText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toModalityScoreView(_ item: ModalityScore) -> ModalityScoreView {
        return ModalityScoreView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            category: Kit.Text.truncate(item.category, limit: 40),
            patientRefText: item.patientRef,
            capacityText: String(item.capacity),
            revision: String(item.revision),
            discountText: String(format: "%.2f", item.discount),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityScoreViews(_ items: [ModalityScore]) -> [ModalityScoreView] {
        var views: [ModalityScoreView] = []
        for item in items {
            views.append(toModalityScoreView(item))
        }
        return views
    }

    static func sumModalityScoreView(_ view: ModalityScoreView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedCapacity) + Double(parsedRevision) + parsedDiscount
    }
}
