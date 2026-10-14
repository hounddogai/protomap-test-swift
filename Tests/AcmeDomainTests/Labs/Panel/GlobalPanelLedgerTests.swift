@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalPanelLedgerTests {
    @Test func startsInIdle() throws {
        let item = Labs.newGlobalPanelLedger("code-277", name: "name-69")
        #expect(item.status == Labs.GlobalPanelLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newGlobalPanelLedger("code-277", name: "name-69")
        try item.moveTo(Labs.GlobalPanelLedgerStatus.warming)
        #expect(item.status == Labs.GlobalPanelLedgerStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newGlobalPanelLedger("code-277", name: "name-69")
        item.status = Labs.GlobalPanelLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalPanelLedgerStatus.idle) }
    }
}
