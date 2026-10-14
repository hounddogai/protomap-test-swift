@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusQuotaTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCensusQuota("code-968", title: "title-901")
        #expect(item.status == BedManagement.CensusQuotaStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newCensusQuota("code-968", title: "title-901")
        try item.moveTo(BedManagement.CensusQuotaStatus.suspended)
        #expect(item.status == BedManagement.CensusQuotaStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCensusQuota("code-968", title: "title-901")
        item.status = BedManagement.CensusQuotaStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusQuotaStatus.draft) }
    }
}
