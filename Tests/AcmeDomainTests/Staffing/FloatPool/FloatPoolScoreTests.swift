@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolScoreTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newFloatPoolScore("code-821", label: "label-595")
        #expect(item.status == Staffing.FloatPoolScoreStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newFloatPoolScore("code-821", label: "label-595")
        try item.moveTo(Staffing.FloatPoolScoreStatus.rejected)
        #expect(item.status == Staffing.FloatPoolScoreStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newFloatPoolScore("code-821", label: "label-595")
        item.status = Staffing.FloatPoolScoreStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolScoreStatus.proposed) }
    }
}
