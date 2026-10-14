@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolTargetTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newCareProtocolTarget("code-420", title: "title-876")
        #expect(item.status == Imaging.CareProtocolTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newCareProtocolTarget("code-420", title: "title-876")
        try item.moveTo(Imaging.CareProtocolTargetStatus.active)
        #expect(item.status == Imaging.CareProtocolTargetStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newCareProtocolTarget("code-420", title: "title-876")
        item.status = Imaging.CareProtocolTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolTargetStatus.draft) }
    }
}
