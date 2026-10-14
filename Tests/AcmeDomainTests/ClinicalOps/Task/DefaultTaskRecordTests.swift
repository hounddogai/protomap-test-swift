@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultTaskRecordTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newDefaultTaskRecord("code-615", label: "label-405")
        #expect(item.status == ClinicalOps.DefaultTaskRecordStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newDefaultTaskRecord("code-615", label: "label-405")
        try item.moveTo(ClinicalOps.DefaultTaskRecordStatus.running)
        #expect(item.status == ClinicalOps.DefaultTaskRecordStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newDefaultTaskRecord("code-615", label: "label-405")
        item.status = ClinicalOps.DefaultTaskRecordStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultTaskRecordStatus.new) }
    }
}
