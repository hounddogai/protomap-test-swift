@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolProfileTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newScheduledCareProtocolProfile("code-570", name: "name-807")
        #expect(item.status == ClinicalOps.ScheduledCareProtocolProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newScheduledCareProtocolProfile("code-570", name: "name-807")
        try item.moveTo(ClinicalOps.ScheduledCareProtocolProfileStatus.completed)
        #expect(item.status == ClinicalOps.ScheduledCareProtocolProfileStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newScheduledCareProtocolProfile("code-570", name: "name-807")
        item.status = ClinicalOps.ScheduledCareProtocolProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledCareProtocolProfileStatus.planned) }
    }
}
