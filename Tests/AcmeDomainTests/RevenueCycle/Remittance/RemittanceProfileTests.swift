@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceProfileTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRemittanceProfile("code-92", name: "name-539")
        #expect(item.status == RevenueCycle.RemittanceProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newRemittanceProfile("code-92", name: "name-539")
        try item.moveTo(RevenueCycle.RemittanceProfileStatus.granted)
        #expect(item.status == RevenueCycle.RemittanceProfileStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRemittanceProfile("code-92", name: "name-539")
        item.status = RevenueCycle.RemittanceProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceProfileStatus.requested) }
    }
}
