import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range record.
    final class ReferenceRangeRecordView {
        var code: String
        var name: String
        var revision: String
        var minimum: String
        var bed: String
        var statusLabel: String

        init(code: String, name: String, revision: String, minimum: String, bed: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revision = revision
            self.minimum = minimum
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeRecordView(_ item: ReferenceRangeRecord) -> ReferenceRangeRecordView {
        return ReferenceRangeRecordView(
            code: item.code,
            name: item.name,
            revision: String(item.revision),
            minimum: String(format: "%.2f", item.minimum),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeRecordViews(_ items: [ReferenceRangeRecord]) -> [ReferenceRangeRecordView] {
        var views: [ReferenceRangeRecordView] = []
        for item in items {
            views.append(toReferenceRangeRecordView(item))
        }
        return views
    }

    static func sumReferenceRangeRecordView(_ view: ReferenceRangeRecordView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedRevision) + parsedMinimum
    }
}
