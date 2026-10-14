@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingChargeSegmentTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newRollingChargeSegment("code-808", name: "name-320")
        #expect(item.status == RevenueCycle.RollingChargeSegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newRollingChargeSegment("code-808", name: "name-320")
        try item.moveTo(RevenueCycle.RollingChargeSegmentStatus.retired)
        #expect(item.status == RevenueCycle.RollingChargeSegmentStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newRollingChargeSegment("code-808", name: "name-320")
        item.status = RevenueCycle.RollingChargeSegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingChargeSegmentStatus.created) }
    }
}
