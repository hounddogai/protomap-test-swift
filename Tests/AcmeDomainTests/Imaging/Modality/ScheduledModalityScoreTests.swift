@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledModalityScoreTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newScheduledModalityScore("code-441", title: "title-295")
        #expect(item.status == Imaging.ScheduledModalityScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newScheduledModalityScore("code-441", title: "title-295")
        try item.moveTo(Imaging.ScheduledModalityScoreStatus.expired)
        #expect(item.status == Imaging.ScheduledModalityScoreStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newScheduledModalityScore("code-441", title: "title-295")
        item.status = Imaging.ScheduledModalityScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledModalityScoreStatus.requested) }
    }
}
