import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality record.
    final class ModalityRecordView {
        var codeText: String
        var label: String
        var minimumText: String
        var graceDays: String
        var maximum: String
        var archived: String
        var ownerID: String
        var externalRef: String
        var statusLabel: String

        init(codeText: String, label: String, minimumText: String, graceDays: String, maximum: String, archived: String, ownerID: String, externalRef: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.minimumText = minimumText
            self.graceDays = graceDays
            self.maximum = maximum
            self.archived = archived
            self.ownerID = ownerID
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toModalityRecordView(_ item: ModalityRecord) -> ModalityRecordView {
        return ModalityRecordView(
            codeText: item.code,
            label: item.label,
            minimumText: String(format: "%.2f", item.minimum),
            graceDays: String(item.graceDays),
            maximum: String(format: "%.2f", item.maximum),
            archived: "\(item.archived)",
            ownerID: item.ownerID,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityRecordViews(_ items: [ModalityRecord]) -> [ModalityRecordView] {
        var views: [ModalityRecordView] = []
        for item in items {
            views.append(toModalityRecordView(item))
        }
        return views
    }

    static func sumModalityRecordView(_ view: ModalityRecordView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMinimum + Double(parsedGraceDays) + parsedMaximum
    }
}
