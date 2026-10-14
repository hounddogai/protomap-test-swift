@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalProxyGroupTests {
    @Test func startsInRequested() throws {
        let item = Consent.newSeasonalProxyGroup("code-786", title: "title-713")
        #expect(item.status == Consent.SeasonalProxyGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newSeasonalProxyGroup("code-786", title: "title-713")
        try item.moveTo(Consent.SeasonalProxyGroupStatus.granted)
        #expect(item.status == Consent.SeasonalProxyGroupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newSeasonalProxyGroup("code-786", title: "title-713")
        item.status = Consent.SeasonalProxyGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalProxyGroupStatus.requested) }
    }
}
