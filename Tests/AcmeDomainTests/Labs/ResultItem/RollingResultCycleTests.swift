@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultCycleTests {
    @Test func startsInIdle() throws {
        let item = Labs.newRollingResultCycle("code-51", title: "title-472")
        #expect(item.status == Labs.RollingResultCycleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newRollingResultCycle("code-51", title: "title-472")
        try item.moveTo(Labs.RollingResultCycleStatus.warming)
        #expect(item.status == Labs.RollingResultCycleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newRollingResultCycle("code-51", title: "title-472")
        item.status = Labs.RollingResultCycleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingResultCycleStatus.idle) }
    }
}
