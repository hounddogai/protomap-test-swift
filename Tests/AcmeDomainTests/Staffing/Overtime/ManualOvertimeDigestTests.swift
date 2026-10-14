@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeDigestTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newManualOvertimeDigest("code-513", name: "name-222")
        #expect(item.status == Staffing.ManualOvertimeDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newManualOvertimeDigest("code-513", name: "name-222")
        try item.moveTo(Staffing.ManualOvertimeDigestStatus.revoked)
        #expect(item.status == Staffing.ManualOvertimeDigestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newManualOvertimeDigest("code-513", name: "name-222")
        item.status = Staffing.ManualOvertimeDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ManualOvertimeDigestStatus.requested) }
    }
}
