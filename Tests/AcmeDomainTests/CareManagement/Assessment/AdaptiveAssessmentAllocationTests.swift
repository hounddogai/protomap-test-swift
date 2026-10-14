@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentAllocationTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newAdaptiveAssessmentAllocation("code-696", name: "name-238")
        #expect(item.status == CareManagement.AdaptiveAssessmentAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newAdaptiveAssessmentAllocation("code-696", name: "name-238")
        try item.moveTo(CareManagement.AdaptiveAssessmentAllocationStatus.granted)
        #expect(item.status == CareManagement.AdaptiveAssessmentAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newAdaptiveAssessmentAllocation("code-696", name: "name-238")
        item.status = CareManagement.AdaptiveAssessmentAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveAssessmentAllocationStatus.requested) }
    }
}
