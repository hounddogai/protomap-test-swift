import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality summary.
    final class ModalitySummaryView {
        var codeText: String
        var labelText: String
        var refills: String
        var pinned: String
        var batchSize: String
        var unit: String
        var retriesText: String
        var graceDays: String
        var startsAt: String
        var checksum: String
        var statusLabel: String

        init(codeText: String, labelText: String, refills: String, pinned: String, batchSize: String, unit: String, retriesText: String, graceDays: String, startsAt: String, checksum: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.refills = refills
            self.pinned = pinned
            self.batchSize = batchSize
            self.unit = unit
            self.retriesText = retriesText
            self.graceDays = graceDays
            self.startsAt = startsAt
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toModalitySummaryView(_ item: ModalitySummary) -> ModalitySummaryView {
        return ModalitySummaryView(
            codeText: item.code,
            labelText: item.label,
            refills: String(item.refills),
            pinned: "\(item.pinned)",
            batchSize: String(item.batchSize),
            unit: item.unit,
            retriesText: String(item.retries),
            graceDays: String(item.graceDays),
            startsAt: String(item.startsAt),
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalitySummaryViews(_ items: [ModalitySummary]) -> [ModalitySummaryView] {
        var views: [ModalitySummaryView] = []
        for item in items {
            views.append(toModalitySummaryView(item))
        }
        return views
    }

    static func sumModalitySummaryView(_ view: ModalitySummaryView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRefills) + Double(parsedBatchSize) + Double(parsedRetries)
    }
}
