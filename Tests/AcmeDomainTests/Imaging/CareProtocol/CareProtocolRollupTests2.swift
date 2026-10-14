@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolRollupTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newCareProtocolRollup("code-189", name: "name-337")
        #expect(item.status == Imaging.CareProtocolRollupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newCareProtocolRollup("code-189", name: "name-337")
        try item.moveTo(Imaging.CareProtocolRollupStatus.published)
        #expect(item.status == Imaging.CareProtocolRollupStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newCareProtocolRollup("code-189", name: "name-337")
        item.status = Imaging.CareProtocolRollupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolRollupStatus.created) }
    }
}
