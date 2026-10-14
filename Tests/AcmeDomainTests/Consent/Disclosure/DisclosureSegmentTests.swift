@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureSegmentTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newDisclosureSegment("code-158", title: "title-913")
        #expect(item.status == Consent.DisclosureSegmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newDisclosureSegment("code-158", title: "title-913")
        try item.moveTo(Consent.DisclosureSegmentStatus.scheduled)
        #expect(item.status == Consent.DisclosureSegmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newDisclosureSegment("code-158", title: "title-913")
        item.status = Consent.DisclosureSegmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureSegmentStatus.planned) }
    }
}
