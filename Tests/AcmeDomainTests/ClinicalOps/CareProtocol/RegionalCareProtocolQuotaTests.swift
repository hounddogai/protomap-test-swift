@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolQuotaTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newRegionalCareProtocolQuota("code-900", name: "name-909")
        #expect(item.status == ClinicalOps.RegionalCareProtocolQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newRegionalCareProtocolQuota("code-900", name: "name-909")
        try item.moveTo(ClinicalOps.RegionalCareProtocolQuotaStatus.published)
        #expect(item.status == ClinicalOps.RegionalCareProtocolQuotaStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newRegionalCareProtocolQuota("code-900", name: "name-909")
        item.status = ClinicalOps.RegionalCareProtocolQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalCareProtocolQuotaStatus.created) }
    }
}
