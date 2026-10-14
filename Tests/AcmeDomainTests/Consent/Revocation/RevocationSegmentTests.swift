@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationSegmentTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRevocationSegment("code-705", label: "label-587")
        #expect(item.status == Consent.RevocationSegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newRevocationSegment("code-705", label: "label-587")
        try item.moveTo(Consent.RevocationSegmentStatus.published)
        #expect(item.status == Consent.RevocationSegmentStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRevocationSegment("code-705", label: "label-587")
        item.status = Consent.RevocationSegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationSegmentStatus.created) }
    }
}
