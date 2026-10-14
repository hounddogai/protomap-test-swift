@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualDispenseMappingTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newManualDispenseMapping("code-701", label: "label-317")
        #expect(item.status == Pharmacy.ManualDispenseMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newManualDispenseMapping("code-701", label: "label-317")
        try item.moveTo(Pharmacy.ManualDispenseMappingStatus.running)
        #expect(item.status == Pharmacy.ManualDispenseMappingStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newManualDispenseMapping("code-701", label: "label-317")
        item.status = Pharmacy.ManualDispenseMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualDispenseMappingStatus.new) }
    }
}
