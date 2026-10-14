@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapQuotaTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newLegacyCareGapQuota("code-794", label: "label-572")
        #expect(item.status == CareManagement.LegacyCareGapQuotaStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newLegacyCareGapQuota("code-794", label: "label-572")
        try item.moveTo(CareManagement.LegacyCareGapQuotaStatus.suspended)
        #expect(item.status == CareManagement.LegacyCareGapQuotaStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newLegacyCareGapQuota("code-794", label: "label-572")
        item.status = CareManagement.LegacyCareGapQuotaStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyCareGapQuotaStatus.draft) }
    }
}
