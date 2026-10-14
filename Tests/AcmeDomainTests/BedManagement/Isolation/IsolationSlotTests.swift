@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationSlotTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newIsolationSlot("code-253", label: "label-187")
        #expect(item.status == BedManagement.IsolationSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newIsolationSlot("code-253", label: "label-187")
        try item.moveTo(BedManagement.IsolationSlotStatus.done)
        #expect(item.status == BedManagement.IsolationSlotStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newIsolationSlot("code-253", label: "label-187")
        item.status = BedManagement.IsolationSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationSlotStatus.new) }
    }
}
