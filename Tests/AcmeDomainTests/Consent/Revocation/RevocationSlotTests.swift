@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationSlotTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRevocationSlot("code-947", title: "title-496")
        #expect(item.status == Consent.RevocationSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newRevocationSlot("code-947", title: "title-496")
        try item.moveTo(Consent.RevocationSlotStatus.validated)
        #expect(item.status == Consent.RevocationSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRevocationSlot("code-947", title: "title-496")
        item.status = Consent.RevocationSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationSlotStatus.created) }
    }
}
