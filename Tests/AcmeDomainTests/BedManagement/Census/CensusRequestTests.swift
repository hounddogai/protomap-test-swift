@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRequestTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCensusRequest("code-132", label: "label-411")
        #expect(item.status == BedManagement.CensusRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newCensusRequest("code-132", label: "label-411")
        try item.moveTo(BedManagement.CensusRequestStatus.active)
        #expect(item.status == BedManagement.CensusRequestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCensusRequest("code-132", label: "label-411")
        item.status = BedManagement.CensusRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusRequestStatus.draft) }
    }
}
