@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingDispenseBundleTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newPendingDispenseBundle("code-780", name: "name-603")
        #expect(item.status == Pharmacy.PendingDispenseBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newPendingDispenseBundle("code-780", name: "name-603")
        try item.moveTo(Pharmacy.PendingDispenseBundleStatus.revoked)
        #expect(item.status == Pharmacy.PendingDispenseBundleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newPendingDispenseBundle("code-780", name: "name-603")
        item.status = Pharmacy.PendingDispenseBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingDispenseBundleStatus.requested) }
    }
}
