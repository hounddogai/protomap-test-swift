@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertNoticeTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newRegionalAlertNotice("code-369", label: "label-865")
        #expect(item.status == ClinicalOps.RegionalAlertNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newRegionalAlertNotice("code-369", label: "label-865")
        try item.moveTo(ClinicalOps.RegionalAlertNoticeStatus.published)
        #expect(item.status == ClinicalOps.RegionalAlertNoticeStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newRegionalAlertNotice("code-369", label: "label-865")
        item.status = ClinicalOps.RegionalAlertNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalAlertNoticeStatus.created) }
    }
}
