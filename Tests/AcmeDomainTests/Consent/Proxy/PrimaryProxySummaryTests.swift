@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryProxySummaryTests {
    @Test func startsInProposed() throws {
        let item = Consent.newPrimaryProxySummary("code-241", name: "name-994")
        #expect(item.status == Consent.PrimaryProxySummaryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newPrimaryProxySummary("code-241", name: "name-994")
        try item.moveTo(Consent.PrimaryProxySummaryStatus.rejected)
        #expect(item.status == Consent.PrimaryProxySummaryStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newPrimaryProxySummary("code-241", name: "name-994")
        item.status = Consent.PrimaryProxySummaryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryProxySummaryStatus.proposed) }
    }
}
