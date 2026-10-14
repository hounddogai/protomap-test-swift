@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalClaimBundleTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newGlobalClaimBundle("code-559", name: "name-975")
        #expect(item.status == RevenueCycle.GlobalClaimBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newGlobalClaimBundle("code-559", name: "name-975")
        try item.moveTo(RevenueCycle.GlobalClaimBundleStatus.completed)
        #expect(item.status == RevenueCycle.GlobalClaimBundleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newGlobalClaimBundle("code-559", name: "name-975")
        item.status = RevenueCycle.GlobalClaimBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalClaimBundleStatus.planned) }
    }
}
