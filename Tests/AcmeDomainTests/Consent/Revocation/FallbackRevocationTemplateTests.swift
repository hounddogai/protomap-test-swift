@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationTemplateTests {
    @Test func startsInDraft() throws {
        let item = Consent.newFallbackRevocationTemplate("code-318", title: "title-434")
        #expect(item.status == Consent.FallbackRevocationTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Consent.newFallbackRevocationTemplate("code-318", title: "title-434")
        try item.moveTo(Consent.FallbackRevocationTemplateStatus.suspended)
        #expect(item.status == Consent.FallbackRevocationTemplateStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newFallbackRevocationTemplate("code-318", title: "title-434")
        item.status = Consent.FallbackRevocationTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackRevocationTemplateStatus.draft) }
    }
}
