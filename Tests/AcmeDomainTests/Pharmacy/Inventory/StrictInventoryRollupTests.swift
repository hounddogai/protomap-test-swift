@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInventoryRollupTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newStrictInventoryRollup("code-645", title: "title-748")
        #expect(item.status == Pharmacy.StrictInventoryRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newStrictInventoryRollup("code-645", title: "title-748")
        try item.moveTo(Pharmacy.StrictInventoryRollupStatus.queued)
        #expect(item.status == Pharmacy.StrictInventoryRollupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newStrictInventoryRollup("code-645", title: "title-748")
        item.status = Pharmacy.StrictInventoryRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictInventoryRollupStatus.new) }
    }
}
