@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeRequestTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newDefaultChargeRequest("code-530", name: "name-484")
        #expect(item.status == RevenueCycle.DefaultChargeRequestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newDefaultChargeRequest("code-530", name: "name-484")
        try item.moveTo(RevenueCycle.DefaultChargeRequestStatus.granted)
        #expect(item.status == RevenueCycle.DefaultChargeRequestStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newDefaultChargeRequest("code-530", name: "name-484")
        item.status = RevenueCycle.DefaultChargeRequestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultChargeRequestStatus.requested) }
    }
}
