@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapQuotaTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newCappedCareGapQuota("code-760", label: "label-638")
        #expect(item.status == CareManagement.CappedCareGapQuotaStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newCappedCareGapQuota("code-760", label: "label-638")
        try item.moveTo(CareManagement.CappedCareGapQuotaStatus.granted)
        #expect(item.status == CareManagement.CappedCareGapQuotaStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newCappedCareGapQuota("code-760", label: "label-638")
        item.status = CareManagement.CappedCareGapQuotaStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedCareGapQuotaStatus.requested) }
    }
}
