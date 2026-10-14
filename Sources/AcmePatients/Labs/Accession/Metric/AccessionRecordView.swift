import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession record.
    final class AccessionRecordView {
        var code: String
        var name: String
        var label: String
        var threshold: String
        var priorityText: String
        var statusLabel: String

        init(code: String, name: String, label: String, threshold: String, priorityText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.label = label
            self.threshold = threshold
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionRecordView(_ item: AccessionRecord) -> AccessionRecordView {
        return AccessionRecordView(
            code: item.code,
            name: item.name,
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionRecordViews(_ items: [AccessionRecord]) -> [AccessionRecordView] {
        var views: [AccessionRecordView] = []
        for item in items {
            views.append(toAccessionRecordView(item))
        }
        return views
    }

    static func sumAccessionRecordView(_ view: AccessionRecordView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedThreshold + Double(parsedPriority)
    }
}
