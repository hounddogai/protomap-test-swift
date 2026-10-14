@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskTargetTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newTieredTaskTarget("code-859", name: "name-596")
        #expect(item.status == ClinicalOps.TieredTaskTargetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newTieredTaskTarget("code-859", name: "name-596")
        try item.moveTo(ClinicalOps.TieredTaskTargetStatus.failed)
        #expect(item.status == ClinicalOps.TieredTaskTargetStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newTieredTaskTarget("code-859", name: "name-596")
        item.status = ClinicalOps.TieredTaskTargetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredTaskTargetStatus.new) }
    }
}
