@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimMappingTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newClaimMapping("code-809", name: "name-188")
        #expect(item.status == RevenueCycle.ClaimMappingStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newClaimMapping("code-809", name: "name-188")
        try item.moveTo(RevenueCycle.ClaimMappingStatus.withdrawn)
        #expect(item.status == RevenueCycle.ClaimMappingStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newClaimMapping("code-809", name: "name-188")
        item.status = RevenueCycle.ClaimMappingStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimMappingStatus.proposed) }
    }
}
