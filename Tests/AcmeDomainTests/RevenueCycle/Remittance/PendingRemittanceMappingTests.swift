@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingRemittanceMappingTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newPendingRemittanceMapping("code-541", title: "title-37")
        #expect(item.status == RevenueCycle.PendingRemittanceMappingStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newPendingRemittanceMapping("code-541", title: "title-37")
        try item.moveTo(RevenueCycle.PendingRemittanceMappingStatus.withdrawn)
        #expect(item.status == RevenueCycle.PendingRemittanceMappingStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newPendingRemittanceMapping("code-541", title: "title-37")
        item.status = RevenueCycle.PendingRemittanceMappingStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingRemittanceMappingStatus.proposed) }
    }
}
