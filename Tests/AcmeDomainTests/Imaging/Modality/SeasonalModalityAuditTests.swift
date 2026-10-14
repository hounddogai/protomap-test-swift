@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalModalityAuditTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newSeasonalModalityAudit("code-483", title: "title-875")
        #expect(item.status == Imaging.SeasonalModalityAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newSeasonalModalityAudit("code-483", title: "title-875")
        try item.moveTo(Imaging.SeasonalModalityAuditStatus.active)
        #expect(item.status == Imaging.SeasonalModalityAuditStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newSeasonalModalityAudit("code-483", title: "title-875")
        item.status = Imaging.SeasonalModalityAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalModalityAuditStatus.draft) }
    }
}
