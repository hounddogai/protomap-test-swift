@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceSegmentTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newRemittanceSegment("code-771", title: "title-741")
        #expect(item.status == RevenueCycle.RemittanceSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newRemittanceSegment("code-771", title: "title-741")
        try item.moveTo(RevenueCycle.RemittanceSegmentStatus.rejected)
        #expect(item.status == RevenueCycle.RemittanceSegmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newRemittanceSegment("code-771", title: "title-741")
        item.status = RevenueCycle.RemittanceSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceSegmentStatus.proposed) }
    }
}
