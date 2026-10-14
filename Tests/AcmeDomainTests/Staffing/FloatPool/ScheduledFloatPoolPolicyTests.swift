@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledFloatPoolPolicyTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newScheduledFloatPoolPolicy("code-323", label: "label-773")
        #expect(item.status == Staffing.ScheduledFloatPoolPolicyStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newScheduledFloatPoolPolicy("code-323", label: "label-773")
        try item.moveTo(Staffing.ScheduledFloatPoolPolicyStatus.granted)
        #expect(item.status == Staffing.ScheduledFloatPoolPolicyStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newScheduledFloatPoolPolicy("code-323", label: "label-773")
        item.status = Staffing.ScheduledFloatPoolPolicyStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledFloatPoolPolicyStatus.requested) }
    }
}
