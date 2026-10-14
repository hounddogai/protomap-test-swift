import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual modality entry.
    final class ManualModalityEntryView {
        var code: String
        var label: String
        var diagnosisCode: String
        var startsAt: String
        var title: String
        var contactEmailText: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, startsAt: String, title: String, contactEmailText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.startsAt = startsAt
            self.title = title
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toManualModalityEntryView(_ item: ManualModalityEntry) -> ManualModalityEntryView {
        return ManualModalityEntryView(
            code: item.code,
            label: item.label,
            diagnosisCode: item.diagnosisCode,
            startsAt: String(item.startsAt),
            title: item.title,
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualModalityEntryViews(_ items: [ManualModalityEntry]) -> [ManualModalityEntryView] {
        var views: [ManualModalityEntryView] = []
        for item in items {
            views.append(toManualModalityEntryView(item))
        }
        return views
    }

    static func sumManualModalityEntryView(_ view: ManualModalityEntryView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
