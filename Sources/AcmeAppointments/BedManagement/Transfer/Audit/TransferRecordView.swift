import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer record.
    final class TransferRecordView {
        var code: String
        var labelText: String
        var attempts: String
        var category: String
        var archivedText: String
        var statusLabel: String

        init(code: String, labelText: String, attempts: String, category: String, archivedText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.attempts = attempts
            self.category = category
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferRecordView(_ item: TransferRecord) -> TransferRecordView {
        return TransferRecordView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            attempts: String(item.attempts),
            category: item.category,
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferRecordViews(_ items: [TransferRecord]) -> [TransferRecordView] {
        var views: [TransferRecordView] = []
        for item in items {
            views.append(toTransferRecordView(item))
        }
        return views
    }

    static func sumTransferRecordView(_ view: TransferRecordView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
