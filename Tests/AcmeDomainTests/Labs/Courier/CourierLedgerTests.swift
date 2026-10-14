@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierLedgerTests {
    @Test func startsInProposed() throws {
        let item = Labs.newCourierLedger("code-276", title: "title-633")
        #expect(item.status == Labs.CourierLedgerStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newCourierLedger("code-276", title: "title-633")
        try item.moveTo(Labs.CourierLedgerStatus.rejected)
        #expect(item.status == Labs.CourierLedgerStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newCourierLedger("code-276", title: "title-633")
        item.status = Labs.CourierLedgerStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierLedgerStatus.proposed) }
    }
}
