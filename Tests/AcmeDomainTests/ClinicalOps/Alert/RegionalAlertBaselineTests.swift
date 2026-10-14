@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertBaselineTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newRegionalAlertBaseline("code-598", label: "label-257")
        #expect(item.status == ClinicalOps.RegionalAlertBaselineStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newRegionalAlertBaseline("code-598", label: "label-257")
        try item.moveTo(ClinicalOps.RegionalAlertBaselineStatus.warming)
        #expect(item.status == ClinicalOps.RegionalAlertBaselineStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newRegionalAlertBaseline("code-598", label: "label-257")
        item.status = ClinicalOps.RegionalAlertBaselineStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalAlertBaselineStatus.idle) }
    }
}
