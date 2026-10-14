@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackProgramMetricTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newFallbackProgramMetric("code-20", name: "name-880")
        #expect(item.status == CareManagement.FallbackProgramMetricStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newFallbackProgramMetric("code-20", name: "name-880")
        try item.moveTo(CareManagement.FallbackProgramMetricStatus.pending)
        #expect(item.status == CareManagement.FallbackProgramMetricStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newFallbackProgramMetric("code-20", name: "name-880")
        item.status = CareManagement.FallbackProgramMetricStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackProgramMetricStatus.draft) }
    }
}
