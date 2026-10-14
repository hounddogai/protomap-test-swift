@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskPolicyTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newTieredTaskPolicy("code-270", title: "title-992")
        #expect(item.status == ClinicalOps.TieredTaskPolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newTieredTaskPolicy("code-270", title: "title-992")
        try item.moveTo(ClinicalOps.TieredTaskPolicyStatus.retired)
        #expect(item.status == ClinicalOps.TieredTaskPolicyStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newTieredTaskPolicy("code-270", title: "title-992")
        item.status = ClinicalOps.TieredTaskPolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredTaskPolicyStatus.created) }
    }
}
