@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessTemplateTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newWitnessTemplate("code-190", title: "title-954")
        #expect(item.status == Consent.WitnessTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newWitnessTemplate("code-190", title: "title-954")
        try item.moveTo(Consent.WitnessTemplateStatus.scheduled)
        #expect(item.status == Consent.WitnessTemplateStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newWitnessTemplate("code-190", title: "title-954")
        item.status = Consent.WitnessTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessTemplateStatus.planned) }
    }
}
