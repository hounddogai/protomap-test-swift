@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanItemTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newManualDischargePlanItem("code-8", title: "title-391")
        #expect(item.status == BedManagement.ManualDischargePlanItemStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newManualDischargePlanItem("code-8", title: "title-391")
        try item.moveTo(BedManagement.ManualDischargePlanItemStatus.warming)
        #expect(item.status == BedManagement.ManualDischargePlanItemStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newManualDischargePlanItem("code-8", title: "title-391")
        item.status = BedManagement.ManualDischargePlanItemStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualDischargePlanItemStatus.idle) }
    }
}
