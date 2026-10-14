@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimePolicyTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newOvertimePolicy("code-773", title: "title-221")
        #expect(item.status == Staffing.OvertimePolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Staffing.newOvertimePolicy("code-773", title: "title-221")
        try item.moveTo(Staffing.OvertimePolicyStatus.archived)
        #expect(item.status == Staffing.OvertimePolicyStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newOvertimePolicy("code-773", title: "title-221")
        item.status = Staffing.OvertimePolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimePolicyStatus.`open`) }
    }
}
