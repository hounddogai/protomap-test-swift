@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientRevocationGroupTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newLenientRevocationGroup("code-26", name: "name-862")
        #expect(item.status == Consent.LenientRevocationGroupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newLenientRevocationGroup("code-26", name: "name-862")
        try item.moveTo(Consent.LenientRevocationGroupStatus.scheduled)
        #expect(item.status == Consent.LenientRevocationGroupStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newLenientRevocationGroup("code-26", name: "name-862")
        item.status = Consent.LenientRevocationGroupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientRevocationGroupStatus.planned) }
    }
}
