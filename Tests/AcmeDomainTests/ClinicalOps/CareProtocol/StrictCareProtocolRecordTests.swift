@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictCareProtocolRecordTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newStrictCareProtocolRecord("code-633", title: "title-372")
        #expect(item.status == ClinicalOps.StrictCareProtocolRecordStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newStrictCareProtocolRecord("code-633", title: "title-372")
        try item.moveTo(ClinicalOps.StrictCareProtocolRecordStatus.validated)
        #expect(item.status == ClinicalOps.StrictCareProtocolRecordStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newStrictCareProtocolRecord("code-633", title: "title-372")
        item.status = ClinicalOps.StrictCareProtocolRecordStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictCareProtocolRecordStatus.created) }
    }
}
