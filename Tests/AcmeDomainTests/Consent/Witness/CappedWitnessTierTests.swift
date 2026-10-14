@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessTierTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newCappedWitnessTier("code-874", name: "name-184")
        #expect(item.status == Consent.CappedWitnessTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Consent.newCappedWitnessTier("code-874", name: "name-184")
        try item.moveTo(Consent.CappedWitnessTierStatus.cancelled)
        #expect(item.status == Consent.CappedWitnessTierStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newCappedWitnessTier("code-874", name: "name-184")
        item.status = Consent.CappedWitnessTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedWitnessTierStatus.planned) }
    }
}
