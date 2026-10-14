@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryDisclosureRecordTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newPrimaryDisclosureRecord("code-562", name: "name-113")
        #expect(item.status == Consent.PrimaryDisclosureRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Consent.newPrimaryDisclosureRecord("code-562", name: "name-113")
        try item.moveTo(Consent.PrimaryDisclosureRecordStatus.cancelled)
        #expect(item.status == Consent.PrimaryDisclosureRecordStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newPrimaryDisclosureRecord("code-562", name: "name-113")
        item.status = Consent.PrimaryDisclosureRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryDisclosureRecordStatus.planned) }
    }
}
