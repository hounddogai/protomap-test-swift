@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedRevocationMilestoneTests {
    @Test func startsInRequested() throws {
        let item = Consent.newWeightedRevocationMilestone("code-567", title: "title-659")
        #expect(item.status == Consent.WeightedRevocationMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newWeightedRevocationMilestone("code-567", title: "title-659")
        try item.moveTo(Consent.WeightedRevocationMilestoneStatus.revoked)
        #expect(item.status == Consent.WeightedRevocationMilestoneStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newWeightedRevocationMilestone("code-567", title: "title-659")
        item.status = Consent.WeightedRevocationMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WeightedRevocationMilestoneStatus.requested) }
    }
}
