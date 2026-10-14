@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalDisclosureSummaryTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRegionalDisclosureSummary("code-821", label: "label-950")
        #expect(item.status == Consent.RegionalDisclosureSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newRegionalDisclosureSummary("code-821", label: "label-950")
        try item.moveTo(Consent.RegionalDisclosureSummaryStatus.validated)
        #expect(item.status == Consent.RegionalDisclosureSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRegionalDisclosureSummary("code-821", label: "label-950")
        item.status = Consent.RegionalDisclosureSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalDisclosureSummaryStatus.created) }
    }
}
