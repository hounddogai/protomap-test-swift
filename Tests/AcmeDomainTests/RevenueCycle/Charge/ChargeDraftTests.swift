@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeDraftTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newChargeDraft("code-88", name: "name-661")
        #expect(item.status == RevenueCycle.ChargeDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newChargeDraft("code-88", name: "name-661")
        try item.moveTo(RevenueCycle.ChargeDraftStatus.rejected)
        #expect(item.status == RevenueCycle.ChargeDraftStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newChargeDraft("code-88", name: "name-661")
        item.status = RevenueCycle.ChargeDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeDraftStatus.proposed) }
    }
}
