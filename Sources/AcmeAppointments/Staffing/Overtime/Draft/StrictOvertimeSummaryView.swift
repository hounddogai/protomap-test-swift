import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict overtime summary.
    final class StrictOvertimeSummaryView {
        var code: String
        var label: String
        var refills: String
        var sequence: String
        var ratio: String
        var threshold: String
        var visible: String
        var amount: String
        var diagnosisCode: String
        var title: String
        var statusLabel: String

        init(code: String, label: String, refills: String, sequence: String, ratio: String, threshold: String, visible: String, amount: String, diagnosisCode: String, title: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.refills = refills
            self.sequence = sequence
            self.ratio = ratio
            self.threshold = threshold
            self.visible = visible
            self.amount = amount
            self.diagnosisCode = diagnosisCode
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toStrictOvertimeSummaryView(_ item: StrictOvertimeSummary) -> StrictOvertimeSummaryView {
        return StrictOvertimeSummaryView(
            code: item.code,
            label: item.label,
            refills: String(item.refills),
            sequence: String(item.sequence),
            ratio: String(format: "%.2f", item.ratio),
            threshold: String(format: "%.2f", item.threshold),
            visible: "\(item.visible)",
            amount: String(format: "%.2f", item.amount),
            diagnosisCode: item.diagnosisCode,
            title: Kit.Text.truncate(item.title, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictOvertimeSummaryViews(_ items: [StrictOvertimeSummary]) -> [StrictOvertimeSummaryView] {
        var views: [StrictOvertimeSummaryView] = []
        for item in items {
            views.append(toStrictOvertimeSummaryView(item))
        }
        return views
    }

    static func sumStrictOvertimeSummaryView(_ view: StrictOvertimeSummaryView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedRefills) + Double(parsedSequence) + parsedRatio
    }
}
