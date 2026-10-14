@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAdjustmentTests {
    @Test func startsInOpen() throws {
        let item = Consent.newWitnessAdjustment("code-961", title: "title-51")
        #expect(item.status == Consent.WitnessAdjustmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newWitnessAdjustment("code-961", title: "title-51")
        try item.moveTo(Consent.WitnessAdjustmentStatus.reopened)
        #expect(item.status == Consent.WitnessAdjustmentStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newWitnessAdjustment("code-961", title: "title-51")
        item.status = Consent.WitnessAdjustmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessAdjustmentStatus.`open`) }
    }
}
