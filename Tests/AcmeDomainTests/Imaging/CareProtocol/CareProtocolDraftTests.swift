@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolDraftTests {
    @Test func startsInNew() throws {
        let item = Imaging.newCareProtocolDraft("code-885", name: "name-754")
        #expect(item.status == Imaging.CareProtocolDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newCareProtocolDraft("code-885", name: "name-754")
        try item.moveTo(Imaging.CareProtocolDraftStatus.queued)
        #expect(item.status == Imaging.CareProtocolDraftStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newCareProtocolDraft("code-885", name: "name-754")
        item.status = Imaging.CareProtocolDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolDraftStatus.new) }
    }
}
