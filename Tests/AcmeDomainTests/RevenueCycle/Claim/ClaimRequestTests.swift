@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRequestTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newClaimRequest("code-347", title: "title-417")
        #expect(item.status == RevenueCycle.ClaimRequestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newClaimRequest("code-347", title: "title-417")
        try item.moveTo(RevenueCycle.ClaimRequestStatus.scheduled)
        #expect(item.status == RevenueCycle.ClaimRequestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newClaimRequest("code-347", title: "title-417")
        item.status = RevenueCycle.ClaimRequestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimRequestStatus.planned) }
    }
}
