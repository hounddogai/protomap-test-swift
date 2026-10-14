import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered care gap audit.
    final class TieredCareGapAuditView {
        var code: String
        var titleText: String
        var checksum: String
        var allergy: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, titleText: String, checksum: String, allergy: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.checksum = checksum
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCareGapAuditView(_ item: TieredCareGapAudit) -> TieredCareGapAuditView {
        return TieredCareGapAuditView(
            code: item.code,
            titleText: item.title,
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCareGapAuditViews(_ items: [TieredCareGapAudit]) -> [TieredCareGapAuditView] {
        var views: [TieredCareGapAuditView] = []
        for item in items {
            views.append(toTieredCareGapAuditView(item))
        }
        return views
    }

    static func sumTieredCareGapAuditView(_ view: TieredCareGapAuditView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedDurationMinutes)
    }
}
