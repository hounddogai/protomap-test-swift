@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientBedBoardTierTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newLenientBedBoardTier("code-332", name: "name-231")
        #expect(item.status == BedManagement.LenientBedBoardTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newLenientBedBoardTier("code-332", name: "name-231")
        try item.moveTo(BedManagement.LenientBedBoardTierStatus.granted)
        #expect(item.status == BedManagement.LenientBedBoardTierStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newLenientBedBoardTier("code-332", name: "name-231")
        item.status = BedManagement.LenientBedBoardTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientBedBoardTierStatus.requested) }
    }
}
