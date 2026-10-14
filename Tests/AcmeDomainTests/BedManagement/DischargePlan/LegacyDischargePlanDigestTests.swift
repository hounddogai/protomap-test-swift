@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyDischargePlanDigestTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newLegacyDischargePlanDigest("code-317", label: "label-51")
        #expect(item.status == BedManagement.LegacyDischargePlanDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newLegacyDischargePlanDigest("code-317", label: "label-51")
        try item.moveTo(BedManagement.LegacyDischargePlanDigestStatus.queued)
        #expect(item.status == BedManagement.LegacyDischargePlanDigestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newLegacyDischargePlanDigest("code-317", label: "label-51")
        item.status = BedManagement.LegacyDischargePlanDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyDischargePlanDigestStatus.new) }
    }
}
