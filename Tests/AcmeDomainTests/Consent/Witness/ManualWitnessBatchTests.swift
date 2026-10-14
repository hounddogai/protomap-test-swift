@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualWitnessBatchTests {
    @Test func startsInCreated() throws {
        let item = Consent.newManualWitnessBatch("code-453", name: "name-715")
        #expect(item.status == Consent.ManualWitnessBatchStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newManualWitnessBatch("code-453", name: "name-715")
        try item.moveTo(Consent.ManualWitnessBatchStatus.validated)
        #expect(item.status == Consent.ManualWitnessBatchStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newManualWitnessBatch("code-453", name: "name-715")
        item.status = Consent.ManualWitnessBatchStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ManualWitnessBatchStatus.created) }
    }
}
