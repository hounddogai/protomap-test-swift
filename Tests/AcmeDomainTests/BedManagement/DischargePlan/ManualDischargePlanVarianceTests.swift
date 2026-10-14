@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanVarianceTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newManualDischargePlanVariance("code-531", label: "label-620")
        #expect(item.status == BedManagement.ManualDischargePlanVarianceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newManualDischargePlanVariance("code-531", label: "label-620")
        try item.moveTo(BedManagement.ManualDischargePlanVarianceStatus.granted)
        #expect(item.status == BedManagement.ManualDischargePlanVarianceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newManualDischargePlanVariance("code-531", label: "label-620")
        item.status = BedManagement.ManualDischargePlanVarianceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualDischargePlanVarianceStatus.requested) }
    }
}
