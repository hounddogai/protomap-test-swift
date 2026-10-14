@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackWitnessDraftTests {
    @Test func startsInDraft() throws {
        let item = Consent.newFallbackWitnessDraft("code-932", title: "title-518")
        #expect(item.status == Consent.FallbackWitnessDraftStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newFallbackWitnessDraft("code-932", title: "title-518")
        try item.moveTo(Consent.FallbackWitnessDraftStatus.active)
        #expect(item.status == Consent.FallbackWitnessDraftStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newFallbackWitnessDraft("code-932", title: "title-518")
        item.status = Consent.FallbackWitnessDraftStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackWitnessDraftStatus.draft) }
    }
}
