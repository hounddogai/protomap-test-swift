@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialTargetTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newDenialTarget("code-366", title: "title-642")
        #expect(item.status == RevenueCycle.DenialTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newDenialTarget("code-366", title: "title-642")
        try item.moveTo(RevenueCycle.DenialTargetStatus.inReview)
        #expect(item.status == RevenueCycle.DenialTargetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newDenialTarget("code-366", title: "title-642")
        item.status = RevenueCycle.DenialTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialTargetStatus.`open`) }
    }
}
