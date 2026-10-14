@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingBundleTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newRoundingBundle("code-494", name: "name-278")
        #expect(item.status == ClinicalOps.RoundingBundleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newRoundingBundle("code-494", name: "name-278")
        try item.moveTo(ClinicalOps.RoundingBundleStatus.published)
        #expect(item.status == ClinicalOps.RoundingBundleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newRoundingBundle("code-494", name: "name-278")
        item.status = ClinicalOps.RoundingBundleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingBundleStatus.created) }
    }
}
