@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedGoalDigestTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newWeightedGoalDigest("code-535", name: "name-170")
        #expect(item.status == CareManagement.WeightedGoalDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = CareManagement.newWeightedGoalDigest("code-535", name: "name-170")
        try item.moveTo(CareManagement.WeightedGoalDigestStatus.withdrawn)
        #expect(item.status == CareManagement.WeightedGoalDigestStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newWeightedGoalDigest("code-535", name: "name-170")
        item.status = CareManagement.WeightedGoalDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedGoalDigestStatus.proposed) }
    }
}
