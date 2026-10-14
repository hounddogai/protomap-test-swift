@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictDisclosureSegmentTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newStrictDisclosureSegment("code-291", name: "name-602")
        #expect(item.status == Consent.StrictDisclosureSegmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newStrictDisclosureSegment("code-291", name: "name-602")
        try item.moveTo(Consent.StrictDisclosureSegmentStatus.scheduled)
        #expect(item.status == Consent.StrictDisclosureSegmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newStrictDisclosureSegment("code-291", name: "name-602")
        item.status = Consent.StrictDisclosureSegmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictDisclosureSegmentStatus.planned) }
    }
}
