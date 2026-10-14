@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInventoryThresholdTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newGlobalInventoryThreshold("code-271", name: "name-66")
        #expect(item.status == Pharmacy.GlobalInventoryThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Pharmacy.newGlobalInventoryThreshold("code-271", name: "name-66")
        try item.moveTo(Pharmacy.GlobalInventoryThresholdStatus.stopped)
        #expect(item.status == Pharmacy.GlobalInventoryThresholdStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newGlobalInventoryThreshold("code-271", name: "name-66")
        item.status = Pharmacy.GlobalInventoryThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalInventoryThresholdStatus.idle) }
    }
}
