@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualProxyScheduleTests {
    @Test func startsInRequested() throws {
        let item = Consent.newManualProxySchedule("code-771", title: "title-115")
        #expect(item.status == Consent.ManualProxyScheduleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newManualProxySchedule("code-771", title: "title-115")
        try item.moveTo(Consent.ManualProxyScheduleStatus.granted)
        #expect(item.status == Consent.ManualProxyScheduleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newManualProxySchedule("code-771", title: "title-115")
        item.status = Consent.ManualProxyScheduleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ManualProxyScheduleStatus.requested) }
    }
}
