@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackDispenseMappingTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newFallbackDispenseMapping("code-54", label: "label-982")
        #expect(item.status == Pharmacy.FallbackDispenseMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newFallbackDispenseMapping("code-54", label: "label-982")
        try item.moveTo(Pharmacy.FallbackDispenseMappingStatus.ready)
        #expect(item.status == Pharmacy.FallbackDispenseMappingStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newFallbackDispenseMapping("code-54", label: "label-982")
        item.status = Pharmacy.FallbackDispenseMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackDispenseMappingStatus.idle) }
    }
}
