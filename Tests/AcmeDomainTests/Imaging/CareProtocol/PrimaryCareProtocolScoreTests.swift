@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryCareProtocolScoreTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newPrimaryCareProtocolScore("code-935", name: "name-346")
        #expect(item.status == Imaging.PrimaryCareProtocolScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Imaging.newPrimaryCareProtocolScore("code-935", name: "name-346")
        try item.moveTo(Imaging.PrimaryCareProtocolScoreStatus.archived)
        #expect(item.status == Imaging.PrimaryCareProtocolScoreStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newPrimaryCareProtocolScore("code-935", name: "name-346")
        item.status = Imaging.PrimaryCareProtocolScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryCareProtocolScoreStatus.`open`) }
    }
}
