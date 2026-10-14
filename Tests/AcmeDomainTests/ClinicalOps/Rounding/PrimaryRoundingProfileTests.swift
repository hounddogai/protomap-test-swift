@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryRoundingProfileTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newPrimaryRoundingProfile("code-336", title: "title-854")
        #expect(item.status == ClinicalOps.PrimaryRoundingProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newPrimaryRoundingProfile("code-336", title: "title-854")
        try item.moveTo(ClinicalOps.PrimaryRoundingProfileStatus.active)
        #expect(item.status == ClinicalOps.PrimaryRoundingProfileStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newPrimaryRoundingProfile("code-336", title: "title-854")
        item.status = ClinicalOps.PrimaryRoundingProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryRoundingProfileStatus.draft) }
    }
}
