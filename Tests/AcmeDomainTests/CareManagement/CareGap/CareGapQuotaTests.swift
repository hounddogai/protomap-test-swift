@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapQuotaTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCareGapQuota("code-519", title: "title-10")
        #expect(item.status == CareManagement.CareGapQuotaStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newCareGapQuota("code-519", title: "title-10")
        try item.moveTo(CareManagement.CareGapQuotaStatus.reopened)
        #expect(item.status == CareManagement.CareGapQuotaStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCareGapQuota("code-519", title: "title-10")
        item.status = CareManagement.CareGapQuotaStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapQuotaStatus.`open`) }
    }
}
