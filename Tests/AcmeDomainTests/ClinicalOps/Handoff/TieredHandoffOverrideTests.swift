@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredHandoffOverrideTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newTieredHandoffOverride("code-844", title: "title-447")
        #expect(item.status == ClinicalOps.TieredHandoffOverrideStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newTieredHandoffOverride("code-844", title: "title-447")
        try item.moveTo(ClinicalOps.TieredHandoffOverrideStatus.rejected)
        #expect(item.status == ClinicalOps.TieredHandoffOverrideStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newTieredHandoffOverride("code-844", title: "title-447")
        item.status = ClinicalOps.TieredHandoffOverrideStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredHandoffOverrideStatus.proposed) }
    }
}
