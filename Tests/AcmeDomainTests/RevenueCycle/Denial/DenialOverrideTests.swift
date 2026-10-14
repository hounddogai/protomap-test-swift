@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialOverrideTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newDenialOverride("code-490", title: "title-253")
        #expect(item.status == RevenueCycle.DenialOverrideStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newDenialOverride("code-490", title: "title-253")
        try item.moveTo(RevenueCycle.DenialOverrideStatus.inProgress)
        #expect(item.status == RevenueCycle.DenialOverrideStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newDenialOverride("code-490", title: "title-253")
        item.status = RevenueCycle.DenialOverrideStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialOverrideStatus.planned) }
    }
}
