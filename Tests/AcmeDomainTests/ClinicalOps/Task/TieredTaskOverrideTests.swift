@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskOverrideTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newTieredTaskOverride("code-401", label: "label-353")
        #expect(item.status == ClinicalOps.TieredTaskOverrideStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newTieredTaskOverride("code-401", label: "label-353")
        try item.moveTo(ClinicalOps.TieredTaskOverrideStatus.retired)
        #expect(item.status == ClinicalOps.TieredTaskOverrideStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newTieredTaskOverride("code-401", label: "label-353")
        item.status = ClinicalOps.TieredTaskOverrideStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredTaskOverrideStatus.created) }
    }
}
