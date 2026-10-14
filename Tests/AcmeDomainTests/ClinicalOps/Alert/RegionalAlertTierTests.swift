@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertTierTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newRegionalAlertTier("code-947", label: "label-169")
        #expect(item.status == ClinicalOps.RegionalAlertTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newRegionalAlertTier("code-947", label: "label-169")
        try item.moveTo(ClinicalOps.RegionalAlertTierStatus.validated)
        #expect(item.status == ClinicalOps.RegionalAlertTierStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newRegionalAlertTier("code-947", label: "label-169")
        item.status = ClinicalOps.RegionalAlertTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalAlertTierStatus.created) }
    }
}
