@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRequestTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newCleaningRequest("code-422", name: "name-545")
        #expect(item.status == BedManagement.CleaningRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newCleaningRequest("code-422", name: "name-545")
        try item.moveTo(BedManagement.CleaningRequestStatus.inReview)
        #expect(item.status == BedManagement.CleaningRequestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newCleaningRequest("code-422", name: "name-545")
        item.status = BedManagement.CleaningRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningRequestStatus.`open`) }
    }
}
