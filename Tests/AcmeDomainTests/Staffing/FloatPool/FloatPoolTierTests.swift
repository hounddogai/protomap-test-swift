@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolTierTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newFloatPoolTier("code-246", title: "title-541")
        #expect(item.status == Staffing.FloatPoolTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newFloatPoolTier("code-246", title: "title-541")
        try item.moveTo(Staffing.FloatPoolTierStatus.inProgress)
        #expect(item.status == Staffing.FloatPoolTierStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newFloatPoolTier("code-246", title: "title-541")
        item.status = Staffing.FloatPoolTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolTierStatus.planned) }
    }
}
