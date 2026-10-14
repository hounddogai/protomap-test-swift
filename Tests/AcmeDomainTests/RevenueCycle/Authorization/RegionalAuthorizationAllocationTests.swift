@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalAuthorizationAllocationTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRegionalAuthorizationAllocation("code-943", label: "label-95")
        #expect(item.status == RevenueCycle.RegionalAuthorizationAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newRegionalAuthorizationAllocation("code-943", label: "label-95")
        try item.moveTo(RevenueCycle.RegionalAuthorizationAllocationStatus.ready)
        #expect(item.status == RevenueCycle.RegionalAuthorizationAllocationStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRegionalAuthorizationAllocation("code-943", label: "label-95")
        item.status = RevenueCycle.RegionalAuthorizationAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalAuthorizationAllocationStatus.idle) }
    }
}
