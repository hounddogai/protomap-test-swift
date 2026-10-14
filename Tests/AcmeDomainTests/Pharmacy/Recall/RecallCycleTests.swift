@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallCycleTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newRecallCycle("code-490", title: "title-486")
        #expect(item.status == Pharmacy.RecallCycleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newRecallCycle("code-490", title: "title-486")
        try item.moveTo(Pharmacy.RecallCycleStatus.revoked)
        #expect(item.status == Pharmacy.RecallCycleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newRecallCycle("code-490", title: "title-486")
        item.status = Pharmacy.RecallCycleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallCycleStatus.requested) }
    }
}
