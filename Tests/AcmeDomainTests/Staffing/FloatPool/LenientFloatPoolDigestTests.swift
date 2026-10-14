@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientFloatPoolDigestTests {
    @Test func startsInNew() throws {
        let item = Staffing.newLenientFloatPoolDigest("code-61", name: "name-854")
        #expect(item.status == Staffing.LenientFloatPoolDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newLenientFloatPoolDigest("code-61", name: "name-854")
        try item.moveTo(Staffing.LenientFloatPoolDigestStatus.running)
        #expect(item.status == Staffing.LenientFloatPoolDigestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newLenientFloatPoolDigest("code-61", name: "name-854")
        item.status = Staffing.LenientFloatPoolDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientFloatPoolDigestStatus.new) }
    }
}
