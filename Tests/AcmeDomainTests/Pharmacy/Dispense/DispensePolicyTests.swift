@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispensePolicyTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDispensePolicy("code-99", label: "label-638")
        #expect(item.status == Pharmacy.DispensePolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newDispensePolicy("code-99", label: "label-638")
        try item.moveTo(Pharmacy.DispensePolicyStatus.ready)
        #expect(item.status == Pharmacy.DispensePolicyStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDispensePolicy("code-99", label: "label-638")
        item.status = Pharmacy.DispensePolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispensePolicyStatus.idle) }
    }
}
