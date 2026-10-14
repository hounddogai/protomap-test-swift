@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapEstimateTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newLegacyCareGapEstimate("code-677", name: "name-281")
        #expect(item.status == CareManagement.LegacyCareGapEstimateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newLegacyCareGapEstimate("code-677", name: "name-281")
        try item.moveTo(CareManagement.LegacyCareGapEstimateStatus.rejected)
        #expect(item.status == CareManagement.LegacyCareGapEstimateStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newLegacyCareGapEstimate("code-677", name: "name-281")
        item.status = CareManagement.LegacyCareGapEstimateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyCareGapEstimateStatus.proposed) }
    }
}
