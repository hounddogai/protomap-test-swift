@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalCareProtocolRuleTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newGlobalCareProtocolRule("code-270", title: "title-913")
        #expect(item.status == ClinicalOps.GlobalCareProtocolRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newGlobalCareProtocolRule("code-270", title: "title-913")
        try item.moveTo(ClinicalOps.GlobalCareProtocolRuleStatus.done)
        #expect(item.status == ClinicalOps.GlobalCareProtocolRuleStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newGlobalCareProtocolRule("code-270", title: "title-913")
        item.status = ClinicalOps.GlobalCareProtocolRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalCareProtocolRuleStatus.new) }
    }
}
