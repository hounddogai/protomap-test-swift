@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureRecordTests {
    @Test func startsInIdle() throws {
        let item = Consent.newCappedDisclosureRecord("code-148", label: "label-593")
        #expect(item.status == Consent.CappedDisclosureRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Consent.newCappedDisclosureRecord("code-148", label: "label-593")
        try item.moveTo(Consent.CappedDisclosureRecordStatus.draining)
        #expect(item.status == Consent.CappedDisclosureRecordStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newCappedDisclosureRecord("code-148", label: "label-593")
        item.status = Consent.CappedDisclosureRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedDisclosureRecordStatus.idle) }
    }
}
