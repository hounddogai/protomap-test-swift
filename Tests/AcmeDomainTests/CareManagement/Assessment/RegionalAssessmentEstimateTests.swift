@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentEstimateTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newRegionalAssessmentEstimate("code-85", name: "name-45")
        #expect(item.status == CareManagement.RegionalAssessmentEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newRegionalAssessmentEstimate("code-85", name: "name-45")
        try item.moveTo(CareManagement.RegionalAssessmentEstimateStatus.warming)
        #expect(item.status == CareManagement.RegionalAssessmentEstimateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newRegionalAssessmentEstimate("code-85", name: "name-45")
        item.status = CareManagement.RegionalAssessmentEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalAssessmentEstimateStatus.idle) }
    }
}
