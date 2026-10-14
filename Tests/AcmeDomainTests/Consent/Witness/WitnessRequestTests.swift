@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessRequestTests {
    @Test func startsInDraft() throws {
        let item = Consent.newWitnessRequest("code-154", name: "name-639")
        #expect(item.status == Consent.WitnessRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Consent.newWitnessRequest("code-154", name: "name-639")
        try item.moveTo(Consent.WitnessRequestStatus.closed)
        #expect(item.status == Consent.WitnessRequestStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newWitnessRequest("code-154", name: "name-639")
        item.status = Consent.WitnessRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessRequestStatus.draft) }
    }
}
