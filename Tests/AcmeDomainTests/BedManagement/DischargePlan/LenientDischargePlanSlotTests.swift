@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientDischargePlanSlotTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newLenientDischargePlanSlot("code-681", label: "label-987")
        #expect(item.status == BedManagement.LenientDischargePlanSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newLenientDischargePlanSlot("code-681", label: "label-987")
        try item.moveTo(BedManagement.LenientDischargePlanSlotStatus.running)
        #expect(item.status == BedManagement.LenientDischargePlanSlotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newLenientDischargePlanSlot("code-681", label: "label-987")
        item.status = BedManagement.LenientDischargePlanSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientDischargePlanSlotStatus.new) }
    }
}
