import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential record.
    final class CredentialRecordView {
        var code: String
        var labelText: String
        var endsAt: String
        var bedText: String
        var windowDays: String
        var specialty: String
        var startsAt: String
        var threshold: String
        var floorValue: String
        var category: String
        var statusLabel: String

        init(code: String, labelText: String, endsAt: String, bedText: String, windowDays: String, specialty: String, startsAt: String, threshold: String, floorValue: String, category: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.endsAt = endsAt
            self.bedText = bedText
            self.windowDays = windowDays
            self.specialty = specialty
            self.startsAt = startsAt
            self.threshold = threshold
            self.floorValue = floorValue
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialRecordView(_ item: CredentialRecord) -> CredentialRecordView {
        return CredentialRecordView(
            code: item.code,
            labelText: item.label,
            endsAt: String(item.endsAt),
            bedText: item.bed,
            windowDays: String(item.windowDays),
            specialty: item.specialty,
            startsAt: String(item.startsAt),
            threshold: String(format: "%.2f", item.threshold),
            floorValue: String(format: "%.2f", item.floorValue),
            category: Kit.Text.truncate(item.category, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialRecordViews(_ items: [CredentialRecord]) -> [CredentialRecordView] {
        var views: [CredentialRecordView] = []
        for item in items {
            views.append(toCredentialRecordView(item))
        }
        return views
    }

    static func sumCredentialRecordView(_ view: CredentialRecordView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedWindowDays) + Double(parsedStartsAt)
    }
}
