@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalResultOverrideTests {
    @Test func startsInIdle() throws {
        let item = Labs.newSeasonalResultOverride("code-354", title: "title-348")
        #expect(item.status == Labs.SeasonalResultOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newSeasonalResultOverride("code-354", title: "title-348")
        try item.moveTo(Labs.SeasonalResultOverrideStatus.draining)
        #expect(item.status == Labs.SeasonalResultOverrideStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newSeasonalResultOverride("code-354", title: "title-348")
        item.status = Labs.SeasonalResultOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalResultOverrideStatus.idle) }
    }
}
