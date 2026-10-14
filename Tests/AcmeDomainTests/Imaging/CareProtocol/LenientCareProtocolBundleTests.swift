@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientCareProtocolBundleTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newLenientCareProtocolBundle("code-275", label: "label-726")
        #expect(item.status == Imaging.LenientCareProtocolBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newLenientCareProtocolBundle("code-275", label: "label-726")
        try item.moveTo(Imaging.LenientCareProtocolBundleStatus.scheduled)
        #expect(item.status == Imaging.LenientCareProtocolBundleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newLenientCareProtocolBundle("code-275", label: "label-726")
        item.status = Imaging.LenientCareProtocolBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientCareProtocolBundleStatus.planned) }
    }
}
