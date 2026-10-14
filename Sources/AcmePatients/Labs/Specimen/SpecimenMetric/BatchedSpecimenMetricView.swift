import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched specimen metric.
    final class BatchedSpecimenMetricView {
        var code: String
        var label: String
        var facility: String
        var sequence: String
        var visitMinutes: String
        var checksumText: String
        var description: String
        var limit: String
        var version: String
        var archived: String
        var rate: String
        var statusLabel: String

        init(code: String, label: String, facility: String, sequence: String, visitMinutes: String, checksumText: String, description: String, limit: String, version: String, archived: String, rate: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.facility = facility
            self.sequence = sequence
            self.visitMinutes = visitMinutes
            self.checksumText = checksumText
            self.description = description
            self.limit = limit
            self.version = version
            self.archived = archived
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedSpecimenMetricView(_ item: BatchedSpecimenMetric) -> BatchedSpecimenMetricView {
        return BatchedSpecimenMetricView(
            code: item.code,
            label: item.label,
            facility: Kit.Text.truncate(item.facility, limit: 40),
            sequence: String(item.sequence),
            visitMinutes: String(item.visitMinutes),
            checksumText: item.checksum,
            description: item.description,
            limit: String(item.limit),
            version: String(item.version),
            archived: "\(item.archived)",
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedSpecimenMetricViews(_ items: [BatchedSpecimenMetric]) -> [BatchedSpecimenMetricView] {
        var views: [BatchedSpecimenMetricView] = []
        for item in items {
            views.append(toBatchedSpecimenMetricView(item))
        }
        return views
    }

    static func sumBatchedSpecimenMetricView(_ view: BatchedSpecimenMetricView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedSequence) + Double(parsedVisitMinutes) + Double(parsedLimit)
    }
}
