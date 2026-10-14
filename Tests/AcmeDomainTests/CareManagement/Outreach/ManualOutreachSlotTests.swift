@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachSlotTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newManualOutreachSlot("code-92", name: "name-126")
        #expect(item.status == CareManagement.ManualOutreachSlotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newManualOutreachSlot("code-92", name: "name-126")
        try item.moveTo(CareManagement.ManualOutreachSlotStatus.scheduled)
        #expect(item.status == CareManagement.ManualOutreachSlotStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newManualOutreachSlot("code-92", name: "name-126")
        item.status = CareManagement.ManualOutreachSlotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualOutreachSlotStatus.planned) }
    }
}
