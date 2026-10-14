@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAdjustmentTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newReadAdjustment("code-94", title: "title-924")
        #expect(item.status == Imaging.ReadAdjustmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newReadAdjustment("code-94", title: "title-924")
        try item.moveTo(Imaging.ReadAdjustmentStatus.warming)
        #expect(item.status == Imaging.ReadAdjustmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newReadAdjustment("code-94", title: "title-924")
        item.status = Imaging.ReadAdjustmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadAdjustmentStatus.idle) }
    }
}
