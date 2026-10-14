@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxySummaryTests {
    @Test func startsInRequested() throws {
        let item = Consent.newLenientProxySummary("code-906", name: "name-602")
        #expect(item.status == Consent.LenientProxySummaryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newLenientProxySummary("code-906", name: "name-602")
        try item.moveTo(Consent.LenientProxySummaryStatus.granted)
        #expect(item.status == Consent.LenientProxySummaryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newLenientProxySummary("code-906", name: "name-602")
        item.status = Consent.LenientProxySummaryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientProxySummaryStatus.requested) }
    }
}
