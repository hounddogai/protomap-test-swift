@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureTargetTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newCappedDisclosureTarget("code-900", title: "title-109")
        #expect(item.status == Consent.CappedDisclosureTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Consent.newCappedDisclosureTarget("code-900", title: "title-109")
        try item.moveTo(Consent.CappedDisclosureTargetStatus.cancelled)
        #expect(item.status == Consent.CappedDisclosureTargetStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newCappedDisclosureTarget("code-900", title: "title-109")
        item.status = Consent.CappedDisclosureTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedDisclosureTargetStatus.planned) }
    }
}
