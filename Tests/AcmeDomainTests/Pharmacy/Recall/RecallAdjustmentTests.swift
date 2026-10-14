@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAdjustmentTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newRecallAdjustment("code-377", title: "title-431")
        #expect(item.status == Pharmacy.RecallAdjustmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newRecallAdjustment("code-377", title: "title-431")
        try item.moveTo(Pharmacy.RecallAdjustmentStatus.retired)
        #expect(item.status == Pharmacy.RecallAdjustmentStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newRecallAdjustment("code-377", title: "title-431")
        item.status = Pharmacy.RecallAdjustmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallAdjustmentStatus.created) }
    }
}
