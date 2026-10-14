@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredDischargePlanRecordTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newTieredDischargePlanRecord("code-466", label: "label-340")
        #expect(item.status == BedManagement.TieredDischargePlanRecordStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newTieredDischargePlanRecord("code-466", label: "label-340")
        try item.moveTo(BedManagement.TieredDischargePlanRecordStatus.queued)
        #expect(item.status == BedManagement.TieredDischargePlanRecordStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newTieredDischargePlanRecord("code-466", label: "label-340")
        item.status = BedManagement.TieredDischargePlanRecordStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TieredDischargePlanRecordStatus.new) }
    }
}
