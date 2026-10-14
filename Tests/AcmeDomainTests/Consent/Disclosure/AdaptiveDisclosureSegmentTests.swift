@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveDisclosureSegmentTests {
    @Test func startsInIdle() throws {
        let item = Consent.newAdaptiveDisclosureSegment("code-818", name: "name-409")
        #expect(item.status == Consent.AdaptiveDisclosureSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newAdaptiveDisclosureSegment("code-818", name: "name-409")
        try item.moveTo(Consent.AdaptiveDisclosureSegmentStatus.warming)
        #expect(item.status == Consent.AdaptiveDisclosureSegmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newAdaptiveDisclosureSegment("code-818", name: "name-409")
        item.status = Consent.AdaptiveDisclosureSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveDisclosureSegmentStatus.idle) }
    }
}
