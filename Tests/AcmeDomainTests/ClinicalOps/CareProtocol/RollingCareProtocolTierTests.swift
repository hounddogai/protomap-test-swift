@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingCareProtocolTierTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newRollingCareProtocolTier("code-386", name: "name-212")
        #expect(item.status == ClinicalOps.RollingCareProtocolTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newRollingCareProtocolTier("code-386", name: "name-212")
        try item.moveTo(ClinicalOps.RollingCareProtocolTierStatus.running)
        #expect(item.status == ClinicalOps.RollingCareProtocolTierStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newRollingCareProtocolTier("code-386", name: "name-212")
        item.status = ClinicalOps.RollingCareProtocolTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingCareProtocolTierStatus.new) }
    }
}
