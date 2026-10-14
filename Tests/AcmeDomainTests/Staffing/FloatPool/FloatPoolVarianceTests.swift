@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolVarianceTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newFloatPoolVariance("code-709", label: "label-792")
        #expect(item.status == Staffing.FloatPoolVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newFloatPoolVariance("code-709", label: "label-792")
        try item.moveTo(Staffing.FloatPoolVarianceStatus.scheduled)
        #expect(item.status == Staffing.FloatPoolVarianceStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newFloatPoolVariance("code-709", label: "label-792")
        item.status = Staffing.FloatPoolVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolVarianceStatus.planned) }
    }
}
