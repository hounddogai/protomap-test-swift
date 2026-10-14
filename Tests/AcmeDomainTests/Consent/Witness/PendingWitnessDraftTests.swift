@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingWitnessDraftTests {
    @Test func startsInOpen() throws {
        let item = Consent.newPendingWitnessDraft("code-651", name: "name-667")
        #expect(item.status == Consent.PendingWitnessDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newPendingWitnessDraft("code-651", name: "name-667")
        try item.moveTo(Consent.PendingWitnessDraftStatus.inReview)
        #expect(item.status == Consent.PendingWitnessDraftStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newPendingWitnessDraft("code-651", name: "name-667")
        item.status = Consent.PendingWitnessDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PendingWitnessDraftStatus.`open`) }
    }
}
