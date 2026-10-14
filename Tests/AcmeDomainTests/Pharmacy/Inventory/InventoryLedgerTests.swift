@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryLedgerTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInventoryLedger("code-578", label: "label-805")
        #expect(item.status == Pharmacy.InventoryLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newInventoryLedger("code-578", label: "label-805")
        try item.moveTo(Pharmacy.InventoryLedgerStatus.running)
        #expect(item.status == Pharmacy.InventoryLedgerStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInventoryLedger("code-578", label: "label-805")
        item.status = Pharmacy.InventoryLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryLedgerStatus.new) }
    }
}
