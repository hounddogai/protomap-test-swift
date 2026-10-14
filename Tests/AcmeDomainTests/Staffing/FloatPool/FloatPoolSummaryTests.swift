@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolSummaryTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newFloatPoolSummary("code-33", title: "title-878")
        #expect(item.status == Staffing.FloatPoolSummaryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newFloatPoolSummary("code-33", title: "title-878")
        try item.moveTo(Staffing.FloatPoolSummaryStatus.revoked)
        #expect(item.status == Staffing.FloatPoolSummaryStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newFloatPoolSummary("code-33", title: "title-878")
        item.status = Staffing.FloatPoolSummaryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolSummaryStatus.requested) }
    }
}
