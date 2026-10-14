@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedOutreachSlotTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newWeightedOutreachSlot("code-408", label: "label-407")
        #expect(item.status == CareManagement.WeightedOutreachSlotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = CareManagement.newWeightedOutreachSlot("code-408", label: "label-407")
        try item.moveTo(CareManagement.WeightedOutreachSlotStatus.completed)
        #expect(item.status == CareManagement.WeightedOutreachSlotStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newWeightedOutreachSlot("code-408", label: "label-407")
        item.status = CareManagement.WeightedOutreachSlotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedOutreachSlotStatus.planned) }
    }
}
