@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityWindowTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newCappedModalityWindow("code-335", name: "name-293")
        #expect(item.status == Imaging.CappedModalityWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newCappedModalityWindow("code-335", name: "name-293")
        try item.moveTo(Imaging.CappedModalityWindowStatus.ready)
        #expect(item.status == Imaging.CappedModalityWindowStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newCappedModalityWindow("code-335", name: "name-293")
        item.status = Imaging.CappedModalityWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedModalityWindowStatus.idle) }
    }
}
