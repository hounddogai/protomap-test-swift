@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultRecallMilestoneTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newDefaultRecallMilestone("code-877", title: "title-553")
        #expect(item.status == Pharmacy.DefaultRecallMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newDefaultRecallMilestone("code-877", title: "title-553")
        try item.moveTo(Pharmacy.DefaultRecallMilestoneStatus.revoked)
        #expect(item.status == Pharmacy.DefaultRecallMilestoneStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newDefaultRecallMilestone("code-877", title: "title-553")
        item.status = Pharmacy.DefaultRecallMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultRecallMilestoneStatus.requested) }
    }
}
