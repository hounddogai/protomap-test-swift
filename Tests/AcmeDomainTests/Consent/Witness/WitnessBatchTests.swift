@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessBatchTests {
    @Test func startsInIdle() throws {
        let item = Consent.newWitnessBatch("code-541", label: "label-902")
        #expect(item.status == Consent.WitnessBatchStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Consent.newWitnessBatch("code-541", label: "label-902")
        try item.moveTo(Consent.WitnessBatchStatus.draining)
        #expect(item.status == Consent.WitnessBatchStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newWitnessBatch("code-541", label: "label-902")
        item.status = Consent.WitnessBatchStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessBatchStatus.idle) }
    }
}
