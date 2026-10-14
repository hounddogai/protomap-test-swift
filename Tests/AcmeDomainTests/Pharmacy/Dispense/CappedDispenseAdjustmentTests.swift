@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseAdjustmentTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newCappedDispenseAdjustment("code-219", title: "title-964")
        #expect(item.status == Pharmacy.CappedDispenseAdjustmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Pharmacy.newCappedDispenseAdjustment("code-219", title: "title-964")
        try item.moveTo(Pharmacy.CappedDispenseAdjustmentStatus.failed)
        #expect(item.status == Pharmacy.CappedDispenseAdjustmentStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newCappedDispenseAdjustment("code-219", title: "title-964")
        item.status = Pharmacy.CappedDispenseAdjustmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedDispenseAdjustmentStatus.new) }
    }
}
