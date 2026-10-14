@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardClaimTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newBedBoardClaim("code-804", name: "name-638")
        #expect(item.status == BedManagement.BedBoardClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newBedBoardClaim("code-804", name: "name-638")
        try item.moveTo(BedManagement.BedBoardClaimStatus.queued)
        #expect(item.status == BedManagement.BedBoardClaimStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newBedBoardClaim("code-804", name: "name-638")
        item.status = BedManagement.BedBoardClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardClaimStatus.new) }
    }
}
