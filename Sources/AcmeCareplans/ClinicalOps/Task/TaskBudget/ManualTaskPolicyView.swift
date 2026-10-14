import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a manual task policy.
    final class ManualTaskPolicyView {
        var code: String
        var label: String
        var segment: String
        var title: String
        var sequenceText: String
        var statusLabel: String

        init(code: String, label: String, segment: String, title: String, sequenceText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segment = segment
            self.title = title
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toManualTaskPolicyView(_ item: ManualTaskPolicy) -> ManualTaskPolicyView {
        return ManualTaskPolicyView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            segment: Kit.Text.truncate(item.segment, limit: 40),
            title: item.title,
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualTaskPolicyViews(_ items: [ManualTaskPolicy]) -> [ManualTaskPolicyView] {
        var views: [ManualTaskPolicyView] = []
        for item in items {
            views.append(toManualTaskPolicyView(item))
        }
        return views
    }

    static func sumManualTaskPolicyView(_ view: ManualTaskPolicyView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedSequence)
    }
}
