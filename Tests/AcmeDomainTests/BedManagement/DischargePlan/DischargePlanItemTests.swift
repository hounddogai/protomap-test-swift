@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanItemTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newDischargePlanItem("code-863", label: "label-324")
        #expect(item.status == BedManagement.DischargePlanItemStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newDischargePlanItem("code-863", label: "label-324")
        try item.moveTo(BedManagement.DischargePlanItemStatus.warming)
        #expect(item.status == BedManagement.DischargePlanItemStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newDischargePlanItem("code-863", label: "label-324")
        item.status = BedManagement.DischargePlanItemStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanItemStatus.idle) }
    }
}
