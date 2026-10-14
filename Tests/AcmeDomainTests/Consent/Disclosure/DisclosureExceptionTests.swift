@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureExceptionTests {
    @Test func startsInNew() throws {
        let item = Consent.newDisclosureException("code-542", name: "name-246")
        #expect(item.status == Consent.DisclosureExceptionStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newDisclosureException("code-542", name: "name-246")
        try item.moveTo(Consent.DisclosureExceptionStatus.queued)
        #expect(item.status == Consent.DisclosureExceptionStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newDisclosureException("code-542", name: "name-246")
        item.status = Consent.DisclosureExceptionStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureExceptionStatus.new) }
    }
}
