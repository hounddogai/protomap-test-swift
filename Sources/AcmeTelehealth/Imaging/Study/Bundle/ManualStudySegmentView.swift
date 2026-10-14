import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual study segment.
    final class ManualStudySegmentView {
        var code: String
        var nameText: String
        var countryText: String
        var minimum: String
        var bed: String
        var batchSize: String
        var statusLabel: String

        init(code: String, nameText: String, countryText: String, minimum: String, bed: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.countryText = countryText
            self.minimum = minimum
            self.bed = bed
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toManualStudySegmentView(_ item: ManualStudySegment) -> ManualStudySegmentView {
        return ManualStudySegmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            countryText: item.country,
            minimum: String(format: "%.2f", item.minimum),
            bed: item.bed,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualStudySegmentViews(_ items: [ManualStudySegment]) -> [ManualStudySegmentView] {
        var views: [ManualStudySegmentView] = []
        for item in items {
            views.append(toManualStudySegmentView(item))
        }
        return views
    }

    static func sumManualStudySegmentView(_ view: ManualStudySegmentView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedMinimum + Double(parsedBatchSize)
    }
}
