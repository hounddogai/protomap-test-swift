@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureWindowTests {
    @Test func startsInCreated() throws {
        let item = Consent.newDisclosureWindow("code-739", name: "name-678")
        #expect(item.status == Consent.DisclosureWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newDisclosureWindow("code-739", name: "name-678")
        try item.moveTo(Consent.DisclosureWindowStatus.validated)
        #expect(item.status == Consent.DisclosureWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newDisclosureWindow("code-739", name: "name-678")
        item.status = Consent.DisclosureWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureWindowStatus.created) }
    }
}
