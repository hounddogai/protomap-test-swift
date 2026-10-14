@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBundleTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newCareProtocolBundle("code-546", name: "name-80")
        #expect(item.status == Imaging.CareProtocolBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newCareProtocolBundle("code-546", name: "name-80")
        try item.moveTo(Imaging.CareProtocolBundleStatus.draining)
        #expect(item.status == Imaging.CareProtocolBundleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newCareProtocolBundle("code-546", name: "name-80")
        item.status = Imaging.CareProtocolBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolBundleStatus.idle) }
    }
}
