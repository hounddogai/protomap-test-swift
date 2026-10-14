@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferSlotTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newWeightedTransferSlot("code-414", name: "name-369")
        #expect(item.status == BedManagement.WeightedTransferSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newWeightedTransferSlot("code-414", name: "name-369")
        try item.moveTo(BedManagement.WeightedTransferSlotStatus.queued)
        #expect(item.status == BedManagement.WeightedTransferSlotStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newWeightedTransferSlot("code-414", name: "name-369")
        item.status = BedManagement.WeightedTransferSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedTransferSlotStatus.new) }
    }
}
