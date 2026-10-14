@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolGroupTests {
    @Test func startsInNew() throws {
        let item = Imaging.newTieredCareProtocolGroup("code-599", title: "title-472")
        #expect(item.status == Imaging.TieredCareProtocolGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newTieredCareProtocolGroup("code-599", title: "title-472")
        try item.moveTo(Imaging.TieredCareProtocolGroupStatus.done)
        #expect(item.status == Imaging.TieredCareProtocolGroupStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newTieredCareProtocolGroup("code-599", title: "title-472")
        item.status = Imaging.TieredCareProtocolGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredCareProtocolGroupStatus.new) }
    }
}
