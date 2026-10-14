@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseGroupTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newDispenseGroup("code-856", name: "name-821")
        #expect(item.status == Pharmacy.DispenseGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newDispenseGroup("code-856", name: "name-821")
        try item.moveTo(Pharmacy.DispenseGroupStatus.revoked)
        #expect(item.status == Pharmacy.DispenseGroupStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newDispenseGroup("code-856", name: "name-821")
        item.status = Pharmacy.DispenseGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseGroupStatus.requested) }
    }
}
