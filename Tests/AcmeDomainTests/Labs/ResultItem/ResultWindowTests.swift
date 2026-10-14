@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultWindowTests {
    @Test func startsInIdle() throws {
        let item = Labs.newResultWindow("code-789", title: "title-544")
        #expect(item.status == Labs.ResultWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newResultWindow("code-789", title: "title-544")
        try item.moveTo(Labs.ResultWindowStatus.draining)
        #expect(item.status == Labs.ResultWindowStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newResultWindow("code-789", title: "title-544")
        item.status = Labs.ResultWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultWindowStatus.idle) }
    }
}
