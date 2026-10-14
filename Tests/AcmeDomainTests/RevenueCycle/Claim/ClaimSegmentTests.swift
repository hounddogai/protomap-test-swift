@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimSegmentTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newClaimSegment("code-915", label: "label-232")
        #expect(item.status == RevenueCycle.ClaimSegmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = RevenueCycle.newClaimSegment("code-915", label: "label-232")
        try item.moveTo(RevenueCycle.ClaimSegmentStatus.failed)
        #expect(item.status == RevenueCycle.ClaimSegmentStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newClaimSegment("code-915", label: "label-232")
        item.status = RevenueCycle.ClaimSegmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimSegmentStatus.new) }
    }
}
