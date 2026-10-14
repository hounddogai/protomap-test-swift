@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolBundleTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newManualCareProtocolBundle("code-456", title: "title-530")
        #expect(item.status == Imaging.ManualCareProtocolBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Imaging.newManualCareProtocolBundle("code-456", title: "title-530")
        try item.moveTo(Imaging.ManualCareProtocolBundleStatus.stopped)
        #expect(item.status == Imaging.ManualCareProtocolBundleStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newManualCareProtocolBundle("code-456", title: "title-530")
        item.status = Imaging.ManualCareProtocolBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualCareProtocolBundleStatus.idle) }
    }
}
