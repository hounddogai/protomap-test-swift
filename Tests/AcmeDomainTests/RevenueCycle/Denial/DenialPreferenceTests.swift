@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialPreferenceTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newDenialPreference("code-756", title: "title-481")
        #expect(item.status == RevenueCycle.DenialPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newDenialPreference("code-756", title: "title-481")
        try item.moveTo(RevenueCycle.DenialPreferenceStatus.warming)
        #expect(item.status == RevenueCycle.DenialPreferenceStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newDenialPreference("code-756", title: "title-481")
        item.status = RevenueCycle.DenialPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialPreferenceStatus.idle) }
    }
}
