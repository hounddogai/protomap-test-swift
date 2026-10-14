import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback panel profile.
    final class FallbackPanelProfileView {
        var code: String
        var title: String
        var graceDays: String
        var discount: String
        var dosageMg: String
        var specialtyText: String
        var revisionText: String
        var sequence: String
        var batchSize: String
        var label: String
        var statusLabel: String

        init(code: String, title: String, graceDays: String, discount: String, dosageMg: String, specialtyText: String, revisionText: String, sequence: String, batchSize: String, label: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.discount = discount
            self.dosageMg = dosageMg
            self.specialtyText = specialtyText
            self.revisionText = revisionText
            self.sequence = sequence
            self.batchSize = batchSize
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackPanelProfileView(_ item: FallbackPanelProfile) -> FallbackPanelProfileView {
        return FallbackPanelProfileView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            graceDays: String(item.graceDays),
            discount: String(format: "%.2f", item.discount),
            dosageMg: String(format: "%.2f", item.dosageMg),
            specialtyText: item.specialty,
            revisionText: String(item.revision),
            sequence: String(item.sequence),
            batchSize: String(item.batchSize),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackPanelProfileViews(_ items: [FallbackPanelProfile]) -> [FallbackPanelProfileView] {
        var views: [FallbackPanelProfileView] = []
        for item in items {
            views.append(toFallbackPanelProfileView(item))
        }
        return views
    }

    static func sumFallbackPanelProfileView(_ view: FallbackPanelProfileView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedGraceDays) + parsedDiscount + parsedDosageMg
    }
}
