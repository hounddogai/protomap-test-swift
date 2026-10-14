@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBaselineTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newDenialBaseline("code-335", label: "label-994")
        #expect(item.status == RevenueCycle.DenialBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newDenialBaseline("code-335", label: "label-994")
        try item.moveTo(RevenueCycle.DenialBaselineStatus.published)
        #expect(item.status == RevenueCycle.DenialBaselineStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newDenialBaseline("code-335", label: "label-994")
        item.status = RevenueCycle.DenialBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialBaselineStatus.created) }
    }
}
