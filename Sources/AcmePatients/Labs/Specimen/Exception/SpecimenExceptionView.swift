import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen exception.
    final class SpecimenExceptionView {
        var codeText: String
        var labelText: String
        var bed: String
        var regionText: String
        var batchSize: String
        var summary: String
        var notesText: String
        var archivedText: String
        var minimum: String
        var retries: String
        var statusLabel: String

        init(codeText: String, labelText: String, bed: String, regionText: String, batchSize: String, summary: String, notesText: String, archivedText: String, minimum: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.bed = bed
            self.regionText = regionText
            self.batchSize = batchSize
            self.summary = summary
            self.notesText = notesText
            self.archivedText = archivedText
            self.minimum = minimum
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenExceptionView(_ item: SpecimenException) -> SpecimenExceptionView {
        return SpecimenExceptionView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            bed: item.bed,
            regionText: item.region,
            batchSize: String(item.batchSize),
            summary: item.summary,
            notesText: Kit.Text.truncate(item.notes, limit: 64),
            archivedText: "\(item.archived)",
            minimum: String(format: "%.2f", item.minimum),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenExceptionViews(_ items: [SpecimenException]) -> [SpecimenExceptionView] {
        var views: [SpecimenExceptionView] = []
        for item in items {
            views.append(toSpecimenExceptionView(item))
        }
        return views
    }

    static func sumSpecimenExceptionView(_ view: SpecimenExceptionView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedBatchSize) + parsedMinimum + Double(parsedRetries)
    }
}
