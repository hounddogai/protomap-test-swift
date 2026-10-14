@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientFloatPoolEstimateTests {
    @Test func startsInNew() throws {
        let item = Staffing.newLenientFloatPoolEstimate("code-899", title: "title-403")
        #expect(item.status == Staffing.LenientFloatPoolEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newLenientFloatPoolEstimate("code-899", title: "title-403")
        try item.moveTo(Staffing.LenientFloatPoolEstimateStatus.queued)
        #expect(item.status == Staffing.LenientFloatPoolEstimateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newLenientFloatPoolEstimate("code-899", title: "title-403")
        item.status = Staffing.LenientFloatPoolEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientFloatPoolEstimateStatus.new) }
    }
}
