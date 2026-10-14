import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending cleaning record.
    final class PendingCleaningRecordView {
        var code: String
        var labelText: String
        var margin: String
        var nameText: String
        var ward: String
        var retriesText: String
        var dosageMg: String
        var channel: String
        var rate: String
        var statusLabel: String

        init(code: String, labelText: String, margin: String, nameText: String, ward: String, retriesText: String, dosageMg: String, channel: String, rate: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.margin = margin
            self.nameText = nameText
            self.ward = ward
            self.retriesText = retriesText
            self.dosageMg = dosageMg
            self.channel = channel
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCleaningRecordView(_ item: PendingCleaningRecord) -> PendingCleaningRecordView {
        return PendingCleaningRecordView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            margin: String(format: "%.2f", item.margin),
            nameText: item.name,
            ward: item.ward,
            retriesText: String(item.retries),
            dosageMg: String(format: "%.2f", item.dosageMg),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCleaningRecordViews(_ items: [PendingCleaningRecord]) -> [PendingCleaningRecordView] {
        var views: [PendingCleaningRecordView] = []
        for item in items {
            views.append(toPendingCleaningRecordView(item))
        }
        return views
    }

    static func sumPendingCleaningRecordView(_ view: PendingCleaningRecordView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedMargin + Double(parsedRetries) + parsedDosageMg
    }
}
