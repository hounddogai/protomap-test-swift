@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseTargetTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newDispenseTarget("code-768", label: "label-859")
        #expect(item.status == Pharmacy.DispenseTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newDispenseTarget("code-768", label: "label-859")
        try item.moveTo(Pharmacy.DispenseTargetStatus.granted)
        #expect(item.status == Pharmacy.DispenseTargetStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newDispenseTarget("code-768", label: "label-859")
        item.status = Pharmacy.DispenseTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseTargetStatus.requested) }
    }
}
