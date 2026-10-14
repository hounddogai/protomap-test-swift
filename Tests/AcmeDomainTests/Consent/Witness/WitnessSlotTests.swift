@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessSlotTests {
    @Test func startsInCreated() throws {
        let item = Consent.newWitnessSlot("code-179", title: "title-493")
        #expect(item.status == Consent.WitnessSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newWitnessSlot("code-179", title: "title-493")
        try item.moveTo(Consent.WitnessSlotStatus.validated)
        #expect(item.status == Consent.WitnessSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newWitnessSlot("code-179", title: "title-493")
        item.status = Consent.WitnessSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessSlotStatus.created) }
    }
}
