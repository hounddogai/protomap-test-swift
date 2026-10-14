@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureRuleTests {
    @Test func startsInNew() throws {
        let item = Consent.newGlobalDisclosureRule("code-797", label: "label-514")
        #expect(item.status == Consent.GlobalDisclosureRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newGlobalDisclosureRule("code-797", label: "label-514")
        try item.moveTo(Consent.GlobalDisclosureRuleStatus.queued)
        #expect(item.status == Consent.GlobalDisclosureRuleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newGlobalDisclosureRule("code-797", label: "label-514")
        item.status = Consent.GlobalDisclosureRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalDisclosureRuleStatus.new) }
    }
}
