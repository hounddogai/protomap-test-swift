@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedOutreachAllocationTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newWeightedOutreachAllocation("code-606", name: "name-808")
        #expect(item.status == CareManagement.WeightedOutreachAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newWeightedOutreachAllocation("code-606", name: "name-808")
        try item.moveTo(CareManagement.WeightedOutreachAllocationStatus.rejected)
        #expect(item.status == CareManagement.WeightedOutreachAllocationStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newWeightedOutreachAllocation("code-606", name: "name-808")
        item.status = CareManagement.WeightedOutreachAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedOutreachAllocationStatus.proposed) }
    }
}
