@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapAllocationTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newGlobalCareGapAllocation("code-994", title: "title-271")
        #expect(item.status == CareManagement.GlobalCareGapAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newGlobalCareGapAllocation("code-994", title: "title-271")
        try item.moveTo(CareManagement.GlobalCareGapAllocationStatus.scheduled)
        #expect(item.status == CareManagement.GlobalCareGapAllocationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newGlobalCareGapAllocation("code-994", title: "title-271")
        item.status = CareManagement.GlobalCareGapAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalCareGapAllocationStatus.planned) }
    }
}
