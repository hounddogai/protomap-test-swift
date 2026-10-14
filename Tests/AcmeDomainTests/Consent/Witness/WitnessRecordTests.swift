@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessRecordTests {
    @Test func startsInIdle() throws {
        let item = Consent.newWitnessRecord("code-433", title: "title-900")
        #expect(item.status == Consent.WitnessRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newWitnessRecord("code-433", title: "title-900")
        try item.moveTo(Consent.WitnessRecordStatus.warming)
        #expect(item.status == Consent.WitnessRecordStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newWitnessRecord("code-433", title: "title-900")
        item.status = Consent.WitnessRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessRecordStatus.idle) }
    }
}
