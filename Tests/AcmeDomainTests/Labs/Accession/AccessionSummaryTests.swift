@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionSummaryTests {
    @Test func startsInRequested() throws {
        let item = Labs.newAccessionSummary("code-232", label: "label-859")
        #expect(item.status == Labs.AccessionSummaryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newAccessionSummary("code-232", label: "label-859")
        try item.moveTo(Labs.AccessionSummaryStatus.expired)
        #expect(item.status == Labs.AccessionSummaryStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newAccessionSummary("code-232", label: "label-859")
        item.status = Labs.AccessionSummaryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionSummaryStatus.requested) }
    }
}
