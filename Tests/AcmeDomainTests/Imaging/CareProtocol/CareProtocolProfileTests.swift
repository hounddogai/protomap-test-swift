@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolProfileTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newCareProtocolProfile("code-894", title: "title-899")
        #expect(item.status == Imaging.CareProtocolProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newCareProtocolProfile("code-894", title: "title-899")
        try item.moveTo(Imaging.CareProtocolProfileStatus.suspended)
        #expect(item.status == Imaging.CareProtocolProfileStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newCareProtocolProfile("code-894", title: "title-899")
        item.status = Imaging.CareProtocolProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolProfileStatus.draft) }
    }
}
