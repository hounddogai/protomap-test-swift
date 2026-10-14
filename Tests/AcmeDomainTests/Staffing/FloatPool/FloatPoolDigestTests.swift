@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolDigestTests {
    @Test func startsInNew() throws {
        let item = Staffing.newFloatPoolDigest("code-877", label: "label-5")
        #expect(item.status == Staffing.FloatPoolDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newFloatPoolDigest("code-877", label: "label-5")
        try item.moveTo(Staffing.FloatPoolDigestStatus.running)
        #expect(item.status == Staffing.FloatPoolDigestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newFloatPoolDigest("code-877", label: "label-5")
        item.status = Staffing.FloatPoolDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolDigestStatus.new) }
    }
}
