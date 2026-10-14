@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolOverrideTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newFloatPoolOverride("code-63", name: "name-265")
        #expect(item.status == Staffing.FloatPoolOverrideStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newFloatPoolOverride("code-63", name: "name-265")
        try item.moveTo(Staffing.FloatPoolOverrideStatus.inProgress)
        #expect(item.status == Staffing.FloatPoolOverrideStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newFloatPoolOverride("code-63", name: "name-265")
        item.status = Staffing.FloatPoolOverrideStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolOverrideStatus.planned) }
    }
}
