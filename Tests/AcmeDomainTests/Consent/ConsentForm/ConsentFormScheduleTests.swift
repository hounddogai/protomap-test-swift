@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormScheduleTests {
    @Test func startsInNew() throws {
        let item = Consent.newConsentFormSchedule("code-449", title: "title-544")
        #expect(item.status == Consent.ConsentFormScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newConsentFormSchedule("code-449", title: "title-544")
        try item.moveTo(Consent.ConsentFormScheduleStatus.queued)
        #expect(item.status == Consent.ConsentFormScheduleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newConsentFormSchedule("code-449", title: "title-544")
        item.status = Consent.ConsentFormScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormScheduleStatus.new) }
    }
}
