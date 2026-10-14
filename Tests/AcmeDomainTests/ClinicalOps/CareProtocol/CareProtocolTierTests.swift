@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolTierTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newCareProtocolTier("code-718", title: "title-353")
        #expect(item.status == ClinicalOps.CareProtocolTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newCareProtocolTier("code-718", title: "title-353")
        try item.moveTo(ClinicalOps.CareProtocolTierStatus.queued)
        #expect(item.status == ClinicalOps.CareProtocolTierStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newCareProtocolTier("code-718", title: "title-353")
        item.status = ClinicalOps.CareProtocolTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolTierStatus.new) }
    }
}
