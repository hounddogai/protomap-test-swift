@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMappingTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newOvertimeMapping("code-596", title: "title-760")
        #expect(item.status == Staffing.OvertimeMappingStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newOvertimeMapping("code-596", title: "title-760")
        try item.moveTo(Staffing.OvertimeMappingStatus.validated)
        #expect(item.status == Staffing.OvertimeMappingStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newOvertimeMapping("code-596", title: "title-760")
        item.status = Staffing.OvertimeMappingStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeMappingStatus.created) }
    }
}
