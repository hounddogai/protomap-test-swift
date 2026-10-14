@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolCheckpointTests {
    @Test func startsInNew() throws {
        let item = Imaging.newCareProtocolCheckpoint("code-808", title: "title-569")
        #expect(item.status == Imaging.CareProtocolCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newCareProtocolCheckpoint("code-808", title: "title-569")
        try item.moveTo(Imaging.CareProtocolCheckpointStatus.running)
        #expect(item.status == Imaging.CareProtocolCheckpointStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newCareProtocolCheckpoint("code-808", title: "title-569")
        item.status = Imaging.CareProtocolCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolCheckpointStatus.new) }
    }
}
