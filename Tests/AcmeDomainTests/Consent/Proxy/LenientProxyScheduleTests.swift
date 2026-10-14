@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyScheduleTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLenientProxySchedule("code-216", name: "name-59")
        #expect(item.status == Consent.LenientProxyScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newLenientProxySchedule("code-216", name: "name-59")
        try item.moveTo(Consent.LenientProxyScheduleStatus.rejected)
        #expect(item.status == Consent.LenientProxyScheduleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLenientProxySchedule("code-216", name: "name-59")
        item.status = Consent.LenientProxyScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientProxyScheduleStatus.proposed) }
    }
}
