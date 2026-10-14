import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment quota.
    final class AssessmentQuotaView {
        var code: String
        var name: String
        var activeText: String
        var createdAtText: String
        var region: String
        var weight: String
        var durationMinutesText: String
        var ward: String
        var statusLabel: String

        init(code: String, name: String, activeText: String, createdAtText: String, region: String, weight: String, durationMinutesText: String, ward: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.activeText = activeText
            self.createdAtText = createdAtText
            self.region = region
            self.weight = weight
            self.durationMinutesText = durationMinutesText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentQuotaView(_ item: AssessmentQuota) -> AssessmentQuotaView {
        return AssessmentQuotaView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            activeText: "\(item.active)",
            createdAtText: String(item.createdAt),
            region: Kit.Text.truncate(item.region, limit: 40),
            weight: String(format: "%.2f", item.weight),
            durationMinutesText: String(item.durationMinutes),
            ward: Kit.Text.truncate(item.ward, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentQuotaViews(_ items: [AssessmentQuota]) -> [AssessmentQuotaView] {
        var views: [AssessmentQuotaView] = []
        for item in items {
            views.append(toAssessmentQuotaView(item))
        }
        return views
    }

    static func sumAssessmentQuotaView(_ view: AssessmentQuotaView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedCreatedAt) + parsedWeight + Double(parsedDurationMinutes)
    }
}
