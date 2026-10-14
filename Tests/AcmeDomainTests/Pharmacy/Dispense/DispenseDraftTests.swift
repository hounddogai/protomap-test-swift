@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseDraftTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newDispenseDraft("code-971", label: "label-720")
        #expect(item.status == Pharmacy.DispenseDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newDispenseDraft("code-971", label: "label-720")
        try item.moveTo(Pharmacy.DispenseDraftStatus.approved)
        #expect(item.status == Pharmacy.DispenseDraftStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newDispenseDraft("code-971", label: "label-720")
        item.status = Pharmacy.DispenseDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseDraftStatus.proposed) }
    }
}
