@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultRequestTests {
    @Test func startsInIdle() throws {
        let item = Labs.newResultRequest("code-734", title: "title-877")
        #expect(item.status == Labs.ResultRequestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newResultRequest("code-734", title: "title-877")
        try item.moveTo(Labs.ResultRequestStatus.draining)
        #expect(item.status == Labs.ResultRequestStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newResultRequest("code-734", title: "title-877")
        item.status = Labs.ResultRequestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultRequestStatus.idle) }
    }
}
