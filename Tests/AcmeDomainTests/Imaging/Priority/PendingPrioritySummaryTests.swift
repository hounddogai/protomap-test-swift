@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingPrioritySummaryTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newPendingPrioritySummary("code-613", name: "name-568")
        #expect(item.status == Imaging.PendingPrioritySummaryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newPendingPrioritySummary("code-613", name: "name-568")
        try item.moveTo(Imaging.PendingPrioritySummaryStatus.revoked)
        #expect(item.status == Imaging.PendingPrioritySummaryStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newPendingPrioritySummary("code-613", name: "name-568")
        item.status = Imaging.PendingPrioritySummaryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingPrioritySummaryStatus.requested) }
    }
}
