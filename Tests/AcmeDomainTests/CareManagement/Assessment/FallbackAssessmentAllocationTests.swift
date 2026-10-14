@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentAllocationTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newFallbackAssessmentAllocation("code-735", name: "name-499")
        #expect(item.status == CareManagement.FallbackAssessmentAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newFallbackAssessmentAllocation("code-735", name: "name-499")
        try item.moveTo(CareManagement.FallbackAssessmentAllocationStatus.granted)
        #expect(item.status == CareManagement.FallbackAssessmentAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newFallbackAssessmentAllocation("code-735", name: "name-499")
        item.status = CareManagement.FallbackAssessmentAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackAssessmentAllocationStatus.requested) }
    }
}
