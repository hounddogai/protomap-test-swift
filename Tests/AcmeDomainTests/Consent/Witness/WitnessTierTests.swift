@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessTierTests {
    @Test func startsInCreated() throws {
        let item = Consent.newWitnessTier("code-85", name: "name-885")
        #expect(item.status == Consent.WitnessTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newWitnessTier("code-85", name: "name-885")
        try item.moveTo(Consent.WitnessTierStatus.published)
        #expect(item.status == Consent.WitnessTierStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newWitnessTier("code-85", name: "name-885")
        item.status = Consent.WitnessTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessTierStatus.created) }
    }
}
