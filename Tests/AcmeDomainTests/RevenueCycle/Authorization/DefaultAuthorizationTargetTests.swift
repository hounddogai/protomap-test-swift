@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultAuthorizationTargetTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newDefaultAuthorizationTarget("code-81", title: "title-869")
        #expect(item.status == RevenueCycle.DefaultAuthorizationTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newDefaultAuthorizationTarget("code-81", title: "title-869")
        try item.moveTo(RevenueCycle.DefaultAuthorizationTargetStatus.completed)
        #expect(item.status == RevenueCycle.DefaultAuthorizationTargetStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newDefaultAuthorizationTarget("code-81", title: "title-869")
        item.status = RevenueCycle.DefaultAuthorizationTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultAuthorizationTargetStatus.planned) }
    }
}
