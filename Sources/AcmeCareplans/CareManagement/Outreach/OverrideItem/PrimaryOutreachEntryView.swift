import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a primary outreach entry.
    final class PrimaryOutreachEntryView {
        var code: String
        var title: String
        var expiresAt: String
        var ward: String
        var batchSize: String
        var statusLabel: String

        init(code: String, title: String, expiresAt: String, ward: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.ward = ward
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryOutreachEntryView(_ item: PrimaryOutreachEntry) -> PrimaryOutreachEntryView {
        return PrimaryOutreachEntryView(
            code: item.code,
            title: item.title,
            expiresAt: String(item.expiresAt),
            ward: Kit.Text.truncate(item.ward, limit: 120),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryOutreachEntryViews(_ items: [PrimaryOutreachEntry]) -> [PrimaryOutreachEntryView] {
        var views: [PrimaryOutreachEntryView] = []
        for item in items {
            views.append(toPrimaryOutreachEntryView(item))
        }
        return views
    }

    static func sumPrimaryOutreachEntryView(_ view: PrimaryOutreachEntryView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedBatchSize)
    }
}
