@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultDischargePlanItemTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newDefaultDischargePlanItem("code-123", name: "name-216")
        #expect(item.status == BedManagement.DefaultDischargePlanItemStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newDefaultDischargePlanItem("code-123", name: "name-216")
        try item.moveTo(BedManagement.DefaultDischargePlanItemStatus.warming)
        #expect(item.status == BedManagement.DefaultDischargePlanItemStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newDefaultDischargePlanItem("code-123", name: "name-216")
        item.status = BedManagement.DefaultDischargePlanItemStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultDischargePlanItemStatus.idle) }
    }
}
