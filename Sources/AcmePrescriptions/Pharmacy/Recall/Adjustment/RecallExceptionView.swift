import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall exception.
    final class RecallExceptionView {
        var code: String
        var name: String
        var revision: String
        var sequence: String
        var graceDays: String
        var threshold: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, name: String, revision: String, sequence: String, graceDays: String, threshold: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revision = revision
            self.sequence = sequence
            self.graceDays = graceDays
            self.threshold = threshold
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toRecallExceptionView(_ item: RecallException) -> RecallExceptionView {
        return RecallExceptionView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            revision: String(item.revision),
            sequence: String(item.sequence),
            graceDays: String(item.graceDays),
            threshold: String(format: "%.2f", item.threshold),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallExceptionViews(_ items: [RecallException]) -> [RecallExceptionView] {
        var views: [RecallExceptionView] = []
        for item in items {
            views.append(toRecallExceptionView(item))
        }
        return views
    }

    static func sumRecallExceptionView(_ view: RecallExceptionView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedRevision) + Double(parsedSequence) + Double(parsedGraceDays)
    }
}
