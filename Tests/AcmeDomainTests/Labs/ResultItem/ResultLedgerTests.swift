@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultLedgerTests {
    @Test func startsInIdle() throws {
        let item = Labs.newResultLedger("code-7", name: "name-119")
        #expect(item.status == Labs.ResultLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newResultLedger("code-7", name: "name-119")
        try item.moveTo(Labs.ResultLedgerStatus.draining)
        #expect(item.status == Labs.ResultLedgerStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newResultLedger("code-7", name: "name-119")
        item.status = Labs.ResultLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultLedgerStatus.idle) }
    }
}
