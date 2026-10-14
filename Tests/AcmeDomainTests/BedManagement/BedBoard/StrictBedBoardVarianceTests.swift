@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardVarianceTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newStrictBedBoardVariance("code-503", name: "name-593")
        #expect(item.status == BedManagement.StrictBedBoardVarianceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newStrictBedBoardVariance("code-503", name: "name-593")
        try item.moveTo(BedManagement.StrictBedBoardVarianceStatus.pending)
        #expect(item.status == BedManagement.StrictBedBoardVarianceStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newStrictBedBoardVariance("code-503", name: "name-593")
        item.status = BedManagement.StrictBedBoardVarianceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictBedBoardVarianceStatus.draft) }
    }
}
