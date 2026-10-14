@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudySummaryTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newTieredStudySummary("code-829", name: "name-410")
        #expect(item.status == Imaging.TieredStudySummaryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newTieredStudySummary("code-829", name: "name-410")
        try item.moveTo(Imaging.TieredStudySummaryStatus.revoked)
        #expect(item.status == Imaging.TieredStudySummaryStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newTieredStudySummary("code-829", name: "name-410")
        item.status = Imaging.TieredStudySummaryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredStudySummaryStatus.requested) }
    }
}
