@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolRuleTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newDefaultCareProtocolRule("code-856", name: "name-799")
        #expect(item.status == ClinicalOps.DefaultCareProtocolRuleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newDefaultCareProtocolRule("code-856", name: "name-799")
        try item.moveTo(ClinicalOps.DefaultCareProtocolRuleStatus.warming)
        #expect(item.status == ClinicalOps.DefaultCareProtocolRuleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newDefaultCareProtocolRule("code-856", name: "name-799")
        item.status = ClinicalOps.DefaultCareProtocolRuleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultCareProtocolRuleStatus.idle) }
    }
}
