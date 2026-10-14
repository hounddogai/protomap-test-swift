@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialDraftTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newDenialDraft("code-179", label: "label-406")
        #expect(item.status == RevenueCycle.DenialDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = RevenueCycle.newDenialDraft("code-179", label: "label-406")
        try item.moveTo(RevenueCycle.DenialDraftStatus.failed)
        #expect(item.status == RevenueCycle.DenialDraftStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newDenialDraft("code-179", label: "label-406")
        item.status = RevenueCycle.DenialDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialDraftStatus.new) }
    }
}
