@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanThresholdTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newManualDischargePlanThreshold("code-701", label: "label-693")
        #expect(item.status == BedManagement.ManualDischargePlanThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = BedManagement.newManualDischargePlanThreshold("code-701", label: "label-693")
        try item.moveTo(BedManagement.ManualDischargePlanThresholdStatus.completed)
        #expect(item.status == BedManagement.ManualDischargePlanThresholdStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newManualDischargePlanThreshold("code-701", label: "label-693")
        item.status = BedManagement.ManualDischargePlanThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualDischargePlanThresholdStatus.planned) }
    }
}
