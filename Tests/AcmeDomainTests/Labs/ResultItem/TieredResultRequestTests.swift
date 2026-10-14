@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredResultRequestTests {
    @Test func startsInIdle() throws {
        let item = Labs.newTieredResultRequest("code-108", title: "title-588")
        #expect(item.status == Labs.TieredResultRequestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newTieredResultRequest("code-108", title: "title-588")
        try item.moveTo(Labs.TieredResultRequestStatus.ready)
        #expect(item.status == Labs.TieredResultRequestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newTieredResultRequest("code-108", title: "title-588")
        item.status = Labs.TieredResultRequestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.TieredResultRequestStatus.idle) }
    }
}
