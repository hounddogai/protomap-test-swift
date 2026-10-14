@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardSlotTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newAdaptiveBedBoardSlot("code-582", name: "name-127")
        #expect(item.status == BedManagement.AdaptiveBedBoardSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newAdaptiveBedBoardSlot("code-582", name: "name-127")
        try item.moveTo(BedManagement.AdaptiveBedBoardSlotStatus.validated)
        #expect(item.status == BedManagement.AdaptiveBedBoardSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newAdaptiveBedBoardSlot("code-582", name: "name-127")
        item.status = BedManagement.AdaptiveBedBoardSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveBedBoardSlotStatus.created) }
    }
}
