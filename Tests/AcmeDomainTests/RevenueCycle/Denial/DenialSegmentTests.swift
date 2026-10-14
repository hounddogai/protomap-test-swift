@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialSegmentTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newDenialSegment("code-970", title: "title-183")
        #expect(item.status == RevenueCycle.DenialSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newDenialSegment("code-970", title: "title-183")
        try item.moveTo(RevenueCycle.DenialSegmentStatus.warming)
        #expect(item.status == RevenueCycle.DenialSegmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newDenialSegment("code-970", title: "title-183")
        item.status = RevenueCycle.DenialSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialSegmentStatus.idle) }
    }
}
