@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAssignmentTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newInventoryAssignment("code-100", name: "name-905")
        #expect(item.status == Pharmacy.InventoryAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newInventoryAssignment("code-100", name: "name-905")
        try item.moveTo(Pharmacy.InventoryAssignmentStatus.warming)
        #expect(item.status == Pharmacy.InventoryAssignmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newInventoryAssignment("code-100", name: "name-905")
        item.status = Pharmacy.InventoryAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryAssignmentStatus.idle) }
    }
}
