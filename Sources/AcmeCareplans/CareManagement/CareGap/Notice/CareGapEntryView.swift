import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap entry.
    final class CareGapEntryView {
        var codeText: String
        var name: String
        var acuity: String
        var notes: String
        var contactEmail: String
        var allergyText: String
        var minimum: String
        var region: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, name: String, acuity: String, notes: String, contactEmail: String, allergyText: String, minimum: String, region: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.acuity = acuity
            self.notes = notes
            self.contactEmail = contactEmail
            self.allergyText = allergyText
            self.minimum = minimum
            self.region = region
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapEntryView(_ item: CareGapEntry) -> CareGapEntryView {
        return CareGapEntryView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            acuity: String(item.acuity),
            notes: item.notes,
            contactEmail: item.contactEmail,
            allergyText: item.allergy,
            minimum: String(format: "%.2f", item.minimum),
            region: item.region,
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapEntryViews(_ items: [CareGapEntry]) -> [CareGapEntryView] {
        var views: [CareGapEntryView] = []
        for item in items {
            views.append(toCareGapEntryView(item))
        }
        return views
    }

    static func sumCareGapEntryView(_ view: CareGapEntryView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedAcuity) + parsedMinimum + Double(parsedVisitMinutes)
    }
}
