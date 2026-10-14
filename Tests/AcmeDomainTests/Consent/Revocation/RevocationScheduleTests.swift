@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationScheduleTests {
    @Test func startsInOpen() throws {
        let item = Consent.newRevocationSchedule("code-947", name: "name-200")
        #expect(item.status == Consent.RevocationScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newRevocationSchedule("code-947", name: "name-200")
        try item.moveTo(Consent.RevocationScheduleStatus.reopened)
        #expect(item.status == Consent.RevocationScheduleStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newRevocationSchedule("code-947", name: "name-200")
        item.status = Consent.RevocationScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationScheduleStatus.`open`) }
    }
}
