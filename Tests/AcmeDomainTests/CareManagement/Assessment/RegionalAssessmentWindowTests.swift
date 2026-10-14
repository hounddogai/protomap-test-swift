@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentWindowTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newRegionalAssessmentWindow("code-858", name: "name-777")
        #expect(item.status == CareManagement.RegionalAssessmentWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = CareManagement.newRegionalAssessmentWindow("code-858", name: "name-777")
        try item.moveTo(CareManagement.RegionalAssessmentWindowStatus.draining)
        #expect(item.status == CareManagement.RegionalAssessmentWindowStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newRegionalAssessmentWindow("code-858", name: "name-777")
        item.status = CareManagement.RegionalAssessmentWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalAssessmentWindowStatus.idle) }
    }
}
