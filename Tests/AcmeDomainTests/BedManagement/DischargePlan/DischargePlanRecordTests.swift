@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanRecordTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newDischargePlanRecord("code-2", title: "title-513")
        #expect(item.status == BedManagement.DischargePlanRecordStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newDischargePlanRecord("code-2", title: "title-513")
        try item.moveTo(BedManagement.DischargePlanRecordStatus.revoked)
        #expect(item.status == BedManagement.DischargePlanRecordStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newDischargePlanRecord("code-2", title: "title-513")
        item.status = BedManagement.DischargePlanRecordStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanRecordStatus.requested) }
    }
}
