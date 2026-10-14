@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictDispenseTargetTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newStrictDispenseTarget("code-608", label: "label-588")
        #expect(item.status == Pharmacy.StrictDispenseTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newStrictDispenseTarget("code-608", label: "label-588")
        try item.moveTo(Pharmacy.StrictDispenseTargetStatus.expired)
        #expect(item.status == Pharmacy.StrictDispenseTargetStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newStrictDispenseTarget("code-608", label: "label-588")
        item.status = Pharmacy.StrictDispenseTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictDispenseTargetStatus.requested) }
    }
}
