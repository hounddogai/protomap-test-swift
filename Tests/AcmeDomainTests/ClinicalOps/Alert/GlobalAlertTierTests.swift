@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertTierTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newGlobalAlertTier("code-28", title: "title-308")
        #expect(item.status == ClinicalOps.GlobalAlertTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newGlobalAlertTier("code-28", title: "title-308")
        try item.moveTo(ClinicalOps.GlobalAlertTierStatus.validated)
        #expect(item.status == ClinicalOps.GlobalAlertTierStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newGlobalAlertTier("code-28", title: "title-308")
        item.status = ClinicalOps.GlobalAlertTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalAlertTierStatus.created) }
    }
}
