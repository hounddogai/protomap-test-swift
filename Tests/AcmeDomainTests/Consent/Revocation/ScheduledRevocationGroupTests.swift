@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledRevocationGroupTests {
    @Test func startsInOpen() throws {
        let item = Consent.newScheduledRevocationGroup("code-822", name: "name-45")
        #expect(item.status == Consent.ScheduledRevocationGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newScheduledRevocationGroup("code-822", name: "name-45")
        try item.moveTo(Consent.ScheduledRevocationGroupStatus.inReview)
        #expect(item.status == Consent.ScheduledRevocationGroupStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newScheduledRevocationGroup("code-822", name: "name-45")
        item.status = Consent.ScheduledRevocationGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledRevocationGroupStatus.`open`) }
    }
}
