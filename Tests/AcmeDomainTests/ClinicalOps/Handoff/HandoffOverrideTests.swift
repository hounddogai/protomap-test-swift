@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffOverrideTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newHandoffOverride("code-834", label: "label-343")
        #expect(item.status == ClinicalOps.HandoffOverrideStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newHandoffOverride("code-834", label: "label-343")
        try item.moveTo(ClinicalOps.HandoffOverrideStatus.published)
        #expect(item.status == ClinicalOps.HandoffOverrideStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newHandoffOverride("code-834", label: "label-343")
        item.status = ClinicalOps.HandoffOverrideStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffOverrideStatus.created) }
    }
}
