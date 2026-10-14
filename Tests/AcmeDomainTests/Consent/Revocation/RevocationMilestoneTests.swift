@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationMilestoneTests {
    @Test func startsInOpen() throws {
        let item = Consent.newRevocationMilestone("code-369", title: "title-655")
        #expect(item.status == Consent.RevocationMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newRevocationMilestone("code-369", title: "title-655")
        try item.moveTo(Consent.RevocationMilestoneStatus.reopened)
        #expect(item.status == Consent.RevocationMilestoneStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newRevocationMilestone("code-369", title: "title-655")
        item.status = Consent.RevocationMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationMilestoneStatus.`open`) }
    }
}
