@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalReadDigestTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newGlobalReadDigest("code-81", name: "name-154")
        #expect(item.status == Imaging.GlobalReadDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newGlobalReadDigest("code-81", name: "name-154")
        try item.moveTo(Imaging.GlobalReadDigestStatus.warming)
        #expect(item.status == Imaging.GlobalReadDigestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newGlobalReadDigest("code-81", name: "name-154")
        item.status = Imaging.GlobalReadDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalReadDigestStatus.idle) }
    }
}
