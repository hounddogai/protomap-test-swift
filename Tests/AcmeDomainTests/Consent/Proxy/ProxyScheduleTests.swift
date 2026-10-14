@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyScheduleTests {
    @Test func startsInProposed() throws {
        let item = Consent.newProxySchedule("code-94", title: "title-79")
        #expect(item.status == Consent.ProxyScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newProxySchedule("code-94", title: "title-79")
        try item.moveTo(Consent.ProxyScheduleStatus.approved)
        #expect(item.status == Consent.ProxyScheduleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newProxySchedule("code-94", title: "title-79")
        item.status = Consent.ProxyScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyScheduleStatus.proposed) }
    }
}
