@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolBaselineTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newCareProtocolBaseline("code-661", title: "title-266")
        #expect(item.status == ClinicalOps.CareProtocolBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newCareProtocolBaseline("code-661", title: "title-266")
        try item.moveTo(ClinicalOps.CareProtocolBaselineStatus.active)
        #expect(item.status == ClinicalOps.CareProtocolBaselineStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newCareProtocolBaseline("code-661", title: "title-266")
        item.status = ClinicalOps.CareProtocolBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolBaselineStatus.draft) }
    }
}
