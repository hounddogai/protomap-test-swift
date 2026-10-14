@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialCycleTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newDenialCycle("code-187", name: "name-936")
        #expect(item.status == RevenueCycle.DenialCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newDenialCycle("code-187", name: "name-936")
        try item.moveTo(RevenueCycle.DenialCycleStatus.published)
        #expect(item.status == RevenueCycle.DenialCycleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newDenialCycle("code-187", name: "name-936")
        item.status = RevenueCycle.DenialCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialCycleStatus.created) }
    }
}
