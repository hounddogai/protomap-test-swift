@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningSlotTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCleaningSlot("code-558", label: "label-528")
        #expect(item.status == BedManagement.CleaningSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newCleaningSlot("code-558", label: "label-528")
        try item.moveTo(BedManagement.CleaningSlotStatus.done)
        #expect(item.status == BedManagement.CleaningSlotStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCleaningSlot("code-558", label: "label-528")
        item.status = BedManagement.CleaningSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningSlotStatus.new) }
    }
}
