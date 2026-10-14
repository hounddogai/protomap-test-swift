@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolNoticeTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newCareProtocolNotice("code-67", title: "title-817")
        #expect(item.status == ClinicalOps.CareProtocolNoticeStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newCareProtocolNotice("code-67", title: "title-817")
        try item.moveTo(ClinicalOps.CareProtocolNoticeStatus.warming)
        #expect(item.status == ClinicalOps.CareProtocolNoticeStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newCareProtocolNotice("code-67", title: "title-817")
        item.status = ClinicalOps.CareProtocolNoticeStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolNoticeStatus.idle) }
    }
}
