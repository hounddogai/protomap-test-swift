@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalDispenseRequestTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRegionalDispenseRequest("code-753", name: "name-586")
        #expect(item.status == Pharmacy.RegionalDispenseRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newRegionalDispenseRequest("code-753", name: "name-586")
        try item.moveTo(Pharmacy.RegionalDispenseRequestStatus.approved)
        #expect(item.status == Pharmacy.RegionalDispenseRequestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRegionalDispenseRequest("code-753", name: "name-586")
        item.status = Pharmacy.RegionalDispenseRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalDispenseRequestStatus.proposed) }
    }
}
