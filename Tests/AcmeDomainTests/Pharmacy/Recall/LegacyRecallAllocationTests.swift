@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallAllocationTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newLegacyRecallAllocation("code-24", title: "title-317")
        #expect(item.status == Pharmacy.LegacyRecallAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newLegacyRecallAllocation("code-24", title: "title-317")
        try item.moveTo(Pharmacy.LegacyRecallAllocationStatus.granted)
        #expect(item.status == Pharmacy.LegacyRecallAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newLegacyRecallAllocation("code-24", title: "title-317")
        item.status = Pharmacy.LegacyRecallAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyRecallAllocationStatus.requested) }
    }
}
