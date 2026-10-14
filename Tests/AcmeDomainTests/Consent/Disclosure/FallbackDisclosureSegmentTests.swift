@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackDisclosureSegmentTests {
    @Test func startsInIdle() throws {
        let item = Consent.newFallbackDisclosureSegment("code-292", name: "name-978")
        #expect(item.status == Consent.FallbackDisclosureSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newFallbackDisclosureSegment("code-292", name: "name-978")
        try item.moveTo(Consent.FallbackDisclosureSegmentStatus.ready)
        #expect(item.status == Consent.FallbackDisclosureSegmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newFallbackDisclosureSegment("code-292", name: "name-978")
        item.status = Consent.FallbackDisclosureSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackDisclosureSegmentStatus.idle) }
    }
}
