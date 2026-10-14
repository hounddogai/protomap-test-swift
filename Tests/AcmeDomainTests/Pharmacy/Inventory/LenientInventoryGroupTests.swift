@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryGroupTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newLenientInventoryGroup("code-625", title: "title-194")
        #expect(item.status == Pharmacy.LenientInventoryGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newLenientInventoryGroup("code-625", title: "title-194")
        try item.moveTo(Pharmacy.LenientInventoryGroupStatus.queued)
        #expect(item.status == Pharmacy.LenientInventoryGroupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newLenientInventoryGroup("code-625", title: "title-194")
        item.status = Pharmacy.LenientInventoryGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientInventoryGroupStatus.new) }
    }
}
