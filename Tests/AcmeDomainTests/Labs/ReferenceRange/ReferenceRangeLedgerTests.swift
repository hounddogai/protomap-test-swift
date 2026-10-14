@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeLedgerTests {
    @Test func startsInIdle() throws {
        let item = Labs.newReferenceRangeLedger("code-872", name: "name-45")
        #expect(item.status == Labs.ReferenceRangeLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newReferenceRangeLedger("code-872", name: "name-45")
        try item.moveTo(Labs.ReferenceRangeLedgerStatus.warming)
        #expect(item.status == Labs.ReferenceRangeLedgerStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newReferenceRangeLedger("code-872", name: "name-45")
        item.status = Labs.ReferenceRangeLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeLedgerStatus.idle) }
    }
}
