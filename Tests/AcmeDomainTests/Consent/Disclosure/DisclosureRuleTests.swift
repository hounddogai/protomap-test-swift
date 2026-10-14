@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureRuleTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newDisclosureRule("code-361", label: "label-765")
        #expect(item.status == Consent.DisclosureRuleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newDisclosureRule("code-361", label: "label-765")
        try item.moveTo(Consent.DisclosureRuleStatus.completed)
        #expect(item.status == Consent.DisclosureRuleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newDisclosureRule("code-361", label: "label-765")
        item.status = Consent.DisclosureRuleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureRuleStatus.planned) }
    }
}
