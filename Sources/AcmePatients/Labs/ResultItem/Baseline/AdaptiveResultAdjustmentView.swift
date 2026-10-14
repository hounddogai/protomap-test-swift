import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive result adjustment.
    final class AdaptiveResultAdjustmentView {
        var codeText: String
        var label: String
        var copay: String
        var archived: String
        var sequence: String
        var statusLabel: String

        init(codeText: String, label: String, copay: String, archived: String, sequence: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.copay = copay
            self.archived = archived
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveResultAdjustmentView(_ item: AdaptiveResultAdjustment) -> AdaptiveResultAdjustmentView {
        return AdaptiveResultAdjustmentView(
            codeText: item.code,
            label: item.label,
            copay: String(format: "%.2f", item.copay),
            archived: "\(item.archived)",
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveResultAdjustmentViews(_ items: [AdaptiveResultAdjustment]) -> [AdaptiveResultAdjustmentView] {
        var views: [AdaptiveResultAdjustmentView] = []
        for item in items {
            views.append(toAdaptiveResultAdjustmentView(item))
        }
        return views
    }

    static func sumAdaptiveResultAdjustmentView(_ view: AdaptiveResultAdjustmentView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedCopay + Double(parsedSequence)
    }
}
