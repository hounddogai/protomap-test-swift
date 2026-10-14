@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftSummaryTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newTieredShiftSummary("code-464", title: "title-798")
        #expect(item.status == Staffing.TieredShiftSummaryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newTieredShiftSummary("code-464", title: "title-798")
        try item.moveTo(Staffing.TieredShiftSummaryStatus.expired)
        #expect(item.status == Staffing.TieredShiftSummaryStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newTieredShiftSummary("code-464", title: "title-798")
        item.status = Staffing.TieredShiftSummaryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredShiftSummaryStatus.requested) }
    }
}
