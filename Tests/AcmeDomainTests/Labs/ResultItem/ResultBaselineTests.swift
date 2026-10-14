@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultBaselineTests {
    @Test func startsInIdle() throws {
        let item = Labs.newResultBaseline("code-609", title: "title-805")
        #expect(item.status == Labs.ResultBaselineStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newResultBaseline("code-609", title: "title-805")
        try item.moveTo(Labs.ResultBaselineStatus.warming)
        #expect(item.status == Labs.ResultBaselineStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newResultBaseline("code-609", title: "title-805")
        item.status = Labs.ResultBaselineStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultBaselineStatus.idle) }
    }
}
