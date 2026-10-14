@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessWindowTests {
    @Test func startsInCreated() throws {
        let item = Consent.newWitnessWindow("code-33", label: "label-242")
        #expect(item.status == Consent.WitnessWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newWitnessWindow("code-33", label: "label-242")
        try item.moveTo(Consent.WitnessWindowStatus.published)
        #expect(item.status == Consent.WitnessWindowStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newWitnessWindow("code-33", label: "label-242")
        item.status = Consent.WitnessWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessWindowStatus.created) }
    }
}
