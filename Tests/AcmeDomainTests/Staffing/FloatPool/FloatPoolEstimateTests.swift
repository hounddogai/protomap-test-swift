@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolEstimateTests {
    @Test func startsInNew() throws {
        let item = Staffing.newFloatPoolEstimate("code-459", name: "name-634")
        #expect(item.status == Staffing.FloatPoolEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Staffing.newFloatPoolEstimate("code-459", name: "name-634")
        try item.moveTo(Staffing.FloatPoolEstimateStatus.done)
        #expect(item.status == Staffing.FloatPoolEstimateStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newFloatPoolEstimate("code-459", name: "name-634")
        item.status = Staffing.FloatPoolEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolEstimateStatus.new) }
    }
}
