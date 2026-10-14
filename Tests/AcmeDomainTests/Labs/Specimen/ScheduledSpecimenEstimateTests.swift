@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledSpecimenEstimateTests {
    @Test func startsInNew() throws {
        let item = Labs.newScheduledSpecimenEstimate("code-990", label: "label-851")
        #expect(item.status == Labs.ScheduledSpecimenEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Labs.newScheduledSpecimenEstimate("code-990", label: "label-851")
        try item.moveTo(Labs.ScheduledSpecimenEstimateStatus.done)
        #expect(item.status == Labs.ScheduledSpecimenEstimateStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newScheduledSpecimenEstimate("code-990", label: "label-851")
        item.status = Labs.ScheduledSpecimenEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledSpecimenEstimateStatus.new) }
    }
}
