@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedCareProtocolTierTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newCappedCareProtocolTier("code-779", name: "name-936")
        #expect(item.status == ClinicalOps.CappedCareProtocolTierStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newCappedCareProtocolTier("code-779", name: "name-936")
        try item.moveTo(ClinicalOps.CappedCareProtocolTierStatus.withdrawn)
        #expect(item.status == ClinicalOps.CappedCareProtocolTierStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newCappedCareProtocolTier("code-779", name: "name-936")
        item.status = ClinicalOps.CappedCareProtocolTierStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedCareProtocolTierStatus.proposed) }
    }
}
