import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol exception.
    final class CareProtocolExceptionView {
        var code: String
        var name: String
        var checksum: String
        var updatedAt: String
        var clinicianIDText: String
        var segment: String
        var notesText: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, name: String, checksum: String, updatedAt: String, clinicianIDText: String, segment: String, notesText: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.updatedAt = updatedAt
            self.clinicianIDText = clinicianIDText
            self.segment = segment
            self.notesText = notesText
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolExceptionView(_ item: CareProtocolException) -> CareProtocolExceptionView {
        return CareProtocolExceptionView(
            code: item.code,
            name: item.name,
            checksum: item.checksum,
            updatedAt: String(item.updatedAt),
            clinicianIDText: item.clinicianID,
            segment: Kit.Text.truncate(item.segment, limit: 120),
            notesText: item.notes,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolExceptionViews(_ items: [CareProtocolException]) -> [CareProtocolExceptionView] {
        var views: [CareProtocolExceptionView] = []
        for item in items {
            views.append(toCareProtocolExceptionView(item))
        }
        return views
    }

    static func sumCareProtocolExceptionView(_ view: CareProtocolExceptionView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedExpiresAt)
    }
}
