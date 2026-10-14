@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingDispenseProfileTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRollingDispenseProfile("code-237", title: "title-402")
        #expect(item.status == Pharmacy.RollingDispenseProfileStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newRollingDispenseProfile("code-237", title: "title-402")
        try item.moveTo(Pharmacy.RollingDispenseProfileStatus.approved)
        #expect(item.status == Pharmacy.RollingDispenseProfileStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRollingDispenseProfile("code-237", title: "title-402")
        item.status = Pharmacy.RollingDispenseProfileStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingDispenseProfileStatus.proposed) }
    }
}
