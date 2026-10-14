@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackRemittanceTargetTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newFallbackRemittanceTarget("code-753", title: "title-87")
        #expect(item.status == RevenueCycle.FallbackRemittanceTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newFallbackRemittanceTarget("code-753", title: "title-87")
        try item.moveTo(RevenueCycle.FallbackRemittanceTargetStatus.inReview)
        #expect(item.status == RevenueCycle.FallbackRemittanceTargetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newFallbackRemittanceTarget("code-753", title: "title-87")
        item.status = RevenueCycle.FallbackRemittanceTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackRemittanceTargetStatus.`open`) }
    }
}
