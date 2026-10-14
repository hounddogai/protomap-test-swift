@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialAllocationTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDenialAllocation("code-638", title: "title-320")
        #expect(item.status == RevenueCycle.DenialAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newDenialAllocation("code-638", title: "title-320")
        try item.moveTo(RevenueCycle.DenialAllocationStatus.withdrawn)
        #expect(item.status == RevenueCycle.DenialAllocationStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDenialAllocation("code-638", title: "title-320")
        item.status = RevenueCycle.DenialAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialAllocationStatus.proposed) }
    }
}
