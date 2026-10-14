@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualAlertRecordTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newManualAlertRecord("code-892", title: "title-659")
        #expect(item.status == ClinicalOps.ManualAlertRecordStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = ClinicalOps.newManualAlertRecord("code-892", title: "title-659")
        try item.moveTo(ClinicalOps.ManualAlertRecordStatus.expired)
        #expect(item.status == ClinicalOps.ManualAlertRecordStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newManualAlertRecord("code-892", title: "title-659")
        item.status = ClinicalOps.ManualAlertRecordStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ManualAlertRecordStatus.requested) }
    }
}
