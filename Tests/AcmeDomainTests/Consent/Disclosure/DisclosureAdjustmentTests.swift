@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = Consent.newDisclosureAdjustment("code-950", label: "label-110")
        #expect(item.status == Consent.DisclosureAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newDisclosureAdjustment("code-950", label: "label-110")
        try item.moveTo(Consent.DisclosureAdjustmentStatus.active)
        #expect(item.status == Consent.DisclosureAdjustmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newDisclosureAdjustment("code-950", label: "label-110")
        item.status = Consent.DisclosureAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureAdjustmentStatus.draft) }
    }
}
