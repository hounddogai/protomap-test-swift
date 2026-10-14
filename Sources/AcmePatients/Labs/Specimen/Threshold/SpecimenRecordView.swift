import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen record.
    final class SpecimenRecordView {
        var code: String
        var name: String
        var versionText: String
        var durationMinutesText: String
        var currency: String
        var rate: String
        var statusLabel: String

        init(code: String, name: String, versionText: String, durationMinutesText: String, currency: String, rate: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.versionText = versionText
            self.durationMinutesText = durationMinutesText
            self.currency = currency
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenRecordView(_ item: SpecimenRecord) -> SpecimenRecordView {
        return SpecimenRecordView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            versionText: String(item.version),
            durationMinutesText: String(item.durationMinutes),
            currency: item.currency,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenRecordViews(_ items: [SpecimenRecord]) -> [SpecimenRecordView] {
        var views: [SpecimenRecordView] = []
        for item in items {
            views.append(toSpecimenRecordView(item))
        }
        return views
    }

    static func sumSpecimenRecordView(_ view: SpecimenRecordView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedVersion) + Double(parsedDurationMinutes) + parsedRate
    }
}
