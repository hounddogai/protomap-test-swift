import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive consent form allocation.
    final class AdaptiveConsentFormAllocationView {
        var code: String
        var name: String
        var quantity: String
        var allergy: String
        var revision: String
        var active: String
        var patientRef: String
        var archivedText: String
        var specialty: String
        var capacity: String
        var facility: String
        var statusLabel: String

        init(code: String, name: String, quantity: String, allergy: String, revision: String, active: String, patientRef: String, archivedText: String, specialty: String, capacity: String, facility: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.allergy = allergy
            self.revision = revision
            self.active = active
            self.patientRef = patientRef
            self.archivedText = archivedText
            self.specialty = specialty
            self.capacity = capacity
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveConsentFormAllocationView(_ item: AdaptiveConsentFormAllocation) -> AdaptiveConsentFormAllocationView {
        return AdaptiveConsentFormAllocationView(
            code: item.code,
            name: item.name,
            quantity: String(item.quantity),
            allergy: item.allergy,
            revision: String(item.revision),
            active: "\(item.active)",
            patientRef: item.patientRef,
            archivedText: "\(item.archived)",
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            capacity: String(item.capacity),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveConsentFormAllocationViews(_ items: [AdaptiveConsentFormAllocation]) -> [AdaptiveConsentFormAllocationView] {
        var views: [AdaptiveConsentFormAllocationView] = []
        for item in items {
            views.append(toAdaptiveConsentFormAllocationView(item))
        }
        return views
    }

    static func sumAdaptiveConsentFormAllocationView(_ view: AdaptiveConsentFormAllocationView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedQuantity) + Double(parsedRevision) + Double(parsedCapacity)
    }
}
