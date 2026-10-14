@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolBaselineTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newFloatPoolBaseline("code-74", label: "label-354")
        #expect(item.status == Staffing.FloatPoolBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newFloatPoolBaseline("code-74", label: "label-354")
        try item.moveTo(Staffing.FloatPoolBaselineStatus.active)
        #expect(item.status == Staffing.FloatPoolBaselineStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newFloatPoolBaseline("code-74", label: "label-354")
        item.status = Staffing.FloatPoolBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolBaselineStatus.draft) }
    }
}
