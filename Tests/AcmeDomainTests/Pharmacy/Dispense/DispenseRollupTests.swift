@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRollupTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newDispenseRollup("code-409", name: "name-844")
        #expect(item.status == Pharmacy.DispenseRollupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newDispenseRollup("code-409", name: "name-844")
        try item.moveTo(Pharmacy.DispenseRollupStatus.approved)
        #expect(item.status == Pharmacy.DispenseRollupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newDispenseRollup("code-409", name: "name-844")
        item.status = Pharmacy.DispenseRollupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseRollupStatus.proposed) }
    }
}
