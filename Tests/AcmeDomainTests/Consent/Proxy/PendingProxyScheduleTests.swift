@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingProxyScheduleTests {
    @Test func startsInRequested() throws {
        let item = Consent.newPendingProxySchedule("code-372", title: "title-328")
        #expect(item.status == Consent.PendingProxyScheduleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newPendingProxySchedule("code-372", title: "title-328")
        try item.moveTo(Consent.PendingProxyScheduleStatus.expired)
        #expect(item.status == Consent.PendingProxyScheduleStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newPendingProxySchedule("code-372", title: "title-328")
        item.status = Consent.PendingProxyScheduleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PendingProxyScheduleStatus.requested) }
    }
}
