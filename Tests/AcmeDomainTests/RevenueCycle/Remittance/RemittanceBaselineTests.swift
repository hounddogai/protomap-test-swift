@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBaselineTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRemittanceBaseline("code-804", title: "title-203")
        #expect(item.status == RevenueCycle.RemittanceBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newRemittanceBaseline("code-804", title: "title-203")
        try item.moveTo(RevenueCycle.RemittanceBaselineStatus.granted)
        #expect(item.status == RevenueCycle.RemittanceBaselineStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRemittanceBaseline("code-804", title: "title-203")
        item.status = RevenueCycle.RemittanceBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceBaselineStatus.requested) }
    }
}
