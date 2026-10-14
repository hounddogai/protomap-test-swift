@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingWitnessWindowTests {
    @Test func startsInOpen() throws {
        let item = Consent.newPendingWitnessWindow("code-516", label: "label-174")
        #expect(item.status == Consent.PendingWitnessWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Consent.newPendingWitnessWindow("code-516", label: "label-174")
        try item.moveTo(Consent.PendingWitnessWindowStatus.archived)
        #expect(item.status == Consent.PendingWitnessWindowStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newPendingWitnessWindow("code-516", label: "label-174")
        item.status = Consent.PendingWitnessWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PendingWitnessWindowStatus.`open`) }
    }
}
