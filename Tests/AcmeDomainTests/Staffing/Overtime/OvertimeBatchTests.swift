@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBatchTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newOvertimeBatch("code-578", name: "name-100")
        #expect(item.status == Staffing.OvertimeBatchStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newOvertimeBatch("code-578", name: "name-100")
        try item.moveTo(Staffing.OvertimeBatchStatus.published)
        #expect(item.status == Staffing.OvertimeBatchStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newOvertimeBatch("code-578", name: "name-100")
        item.status = Staffing.OvertimeBatchStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeBatchStatus.created) }
    }
}
