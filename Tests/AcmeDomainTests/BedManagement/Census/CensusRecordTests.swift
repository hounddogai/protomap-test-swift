@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRecordTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newCensusRecord("code-527", label: "label-960")
        #expect(item.status == BedManagement.CensusRecordStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newCensusRecord("code-527", label: "label-960")
        try item.moveTo(BedManagement.CensusRecordStatus.inReview)
        #expect(item.status == BedManagement.CensusRecordStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newCensusRecord("code-527", label: "label-960")
        item.status = BedManagement.CensusRecordStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusRecordStatus.`open`) }
    }
}
