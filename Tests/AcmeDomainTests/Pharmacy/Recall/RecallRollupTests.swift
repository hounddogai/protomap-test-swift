@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallRollupTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newRecallRollup("code-326", name: "name-533")
        #expect(item.status == Pharmacy.RecallRollupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newRecallRollup("code-326", name: "name-533")
        try item.moveTo(Pharmacy.RecallRollupStatus.expired)
        #expect(item.status == Pharmacy.RecallRollupStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newRecallRollup("code-326", name: "name-533")
        item.status = Pharmacy.RecallRollupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallRollupStatus.requested) }
    }
}
