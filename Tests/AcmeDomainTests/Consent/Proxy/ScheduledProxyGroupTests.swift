@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyGroupTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newScheduledProxyGroup("code-535", label: "label-638")
        #expect(item.status == Consent.ScheduledProxyGroupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newScheduledProxyGroup("code-535", label: "label-638")
        try item.moveTo(Consent.ScheduledProxyGroupStatus.scheduled)
        #expect(item.status == Consent.ScheduledProxyGroupStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newScheduledProxyGroup("code-535", label: "label-638")
        item.status = Consent.ScheduledProxyGroupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledProxyGroupStatus.planned) }
    }
}
