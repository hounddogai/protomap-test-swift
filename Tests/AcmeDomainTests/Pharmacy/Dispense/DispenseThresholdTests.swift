@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseThresholdTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newDispenseThreshold("code-879", label: "label-30")
        #expect(item.status == Pharmacy.DispenseThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Pharmacy.newDispenseThreshold("code-879", label: "label-30")
        try item.moveTo(Pharmacy.DispenseThresholdStatus.cancelled)
        #expect(item.status == Pharmacy.DispenseThresholdStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newDispenseThreshold("code-879", label: "label-30")
        item.status = Pharmacy.DispenseThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseThresholdStatus.planned) }
    }
}
