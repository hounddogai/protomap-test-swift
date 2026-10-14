@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseAdjustmentTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDispenseAdjustment("code-434", name: "name-328")
        #expect(item.status == Pharmacy.DispenseAdjustmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newDispenseAdjustment("code-434", name: "name-328")
        try item.moveTo(Pharmacy.DispenseAdjustmentStatus.warming)
        #expect(item.status == Pharmacy.DispenseAdjustmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDispenseAdjustment("code-434", name: "name-328")
        item.status = Pharmacy.DispenseAdjustmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseAdjustmentStatus.idle) }
    }
}
