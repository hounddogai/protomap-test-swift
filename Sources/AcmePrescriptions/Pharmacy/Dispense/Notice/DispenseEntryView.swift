import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense entry.
    final class DispenseEntryView {
        var code: String
        var titleText: String
        var durationMinutesText: String
        var threshold: String
        var ownerIDText: String
        var discount: String
        var floorValue: String
        var specialtyText: String
        var active: String
        var clinicianID: String
        var archived: String
        var statusLabel: String

        init(code: String, titleText: String, durationMinutesText: String, threshold: String, ownerIDText: String, discount: String, floorValue: String, specialtyText: String, active: String, clinicianID: String, archived: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.durationMinutesText = durationMinutesText
            self.threshold = threshold
            self.ownerIDText = ownerIDText
            self.discount = discount
            self.floorValue = floorValue
            self.specialtyText = specialtyText
            self.active = active
            self.clinicianID = clinicianID
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseEntryView(_ item: DispenseEntry) -> DispenseEntryView {
        return DispenseEntryView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            durationMinutesText: String(item.durationMinutes),
            threshold: String(format: "%.2f", item.threshold),
            ownerIDText: item.ownerID,
            discount: String(format: "%.2f", item.discount),
            floorValue: String(format: "%.2f", item.floorValue),
            specialtyText: item.specialty,
            active: "\(item.active)",
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseEntryViews(_ items: [DispenseEntry]) -> [DispenseEntryView] {
        var views: [DispenseEntryView] = []
        for item in items {
            views.append(toDispenseEntryView(item))
        }
        return views
    }

    static func sumDispenseEntryView(_ view: DispenseEntryView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedDurationMinutes) + parsedThreshold + parsedDiscount
    }
}
