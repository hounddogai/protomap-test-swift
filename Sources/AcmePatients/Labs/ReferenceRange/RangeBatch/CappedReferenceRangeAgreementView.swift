import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped reference range agreement.
    final class CappedReferenceRangeAgreementView {
        var code: String
        var nameText: String
        var startsAt: String
        var capacityText: String
        var ownerID: String
        var encounterID: String
        var archivedText: String
        var summary: String
        var ward: String
        var statusLabel: String

        init(code: String, nameText: String, startsAt: String, capacityText: String, ownerID: String, encounterID: String, archivedText: String, summary: String, ward: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.startsAt = startsAt
            self.capacityText = capacityText
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.archivedText = archivedText
            self.summary = summary
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toCappedReferenceRangeAgreementView(_ item: CappedReferenceRangeAgreement) -> CappedReferenceRangeAgreementView {
        return CappedReferenceRangeAgreementView(
            code: item.code,
            nameText: item.name,
            startsAt: String(item.startsAt),
            capacityText: String(item.capacity),
            ownerID: item.ownerID,
            encounterID: item.encounterID,
            archivedText: "\(item.archived)",
            summary: item.summary,
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedReferenceRangeAgreementViews(_ items: [CappedReferenceRangeAgreement]) -> [CappedReferenceRangeAgreementView] {
        var views: [CappedReferenceRangeAgreementView] = []
        for item in items {
            views.append(toCappedReferenceRangeAgreementView(item))
        }
        return views
    }

    static func sumCappedReferenceRangeAgreementView(_ view: CappedReferenceRangeAgreementView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedCapacity)
    }
}
