import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist window.
    final class WorklistWindowView {
        var code: String
        var title: String
        var endsAt: String
        var limit: String
        var bedText: String
        var externalRef: String
        var sequence: String
        var patientRef: String
        var statusLabel: String

        init(code: String, title: String, endsAt: String, limit: String, bedText: String, externalRef: String, sequence: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.limit = limit
            self.bedText = bedText
            self.externalRef = externalRef
            self.sequence = sequence
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistWindowView(_ item: WorklistWindow) -> WorklistWindowView {
        return WorklistWindowView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            endsAt: String(item.endsAt),
            limit: String(item.limit),
            bedText: item.bed,
            externalRef: item.externalRef,
            sequence: String(item.sequence),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistWindowViews(_ items: [WorklistWindow]) -> [WorklistWindowView] {
        var views: [WorklistWindowView] = []
        for item in items {
            views.append(toWorklistWindowView(item))
        }
        return views
    }

    static func sumWorklistWindowView(_ view: WorklistWindowView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedLimit) + Double(parsedSequence)
    }
}
