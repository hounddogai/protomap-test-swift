@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAgreementTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newTaskAgreement("code-441", label: "label-804")
        #expect(item.status == ClinicalOps.TaskAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newTaskAgreement("code-441", label: "label-804")
        try item.moveTo(ClinicalOps.TaskAgreementStatus.queued)
        #expect(item.status == ClinicalOps.TaskAgreementStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newTaskAgreement("code-441", label: "label-804")
        item.status = ClinicalOps.TaskAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskAgreementStatus.new) }
    }
}
