@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessGroupTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newWitnessGroup("code-874", label: "label-447")
        #expect(item.status == Consent.WitnessGroupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newWitnessGroup("code-874", label: "label-447")
        try item.moveTo(Consent.WitnessGroupStatus.completed)
        #expect(item.status == Consent.WitnessGroupStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newWitnessGroup("code-874", label: "label-447")
        item.status = Consent.WitnessGroupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessGroupStatus.planned) }
    }
}
