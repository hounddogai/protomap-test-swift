@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolAssignmentTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newCareProtocolAssignment("code-554", label: "label-486")
        #expect(item.status == ClinicalOps.CareProtocolAssignmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newCareProtocolAssignment("code-554", label: "label-486")
        try item.moveTo(ClinicalOps.CareProtocolAssignmentStatus.queued)
        #expect(item.status == ClinicalOps.CareProtocolAssignmentStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newCareProtocolAssignment("code-554", label: "label-486")
        item.status = ClinicalOps.CareProtocolAssignmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolAssignmentStatus.new) }
    }
}
