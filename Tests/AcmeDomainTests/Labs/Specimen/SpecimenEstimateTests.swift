@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenEstimateTests {
    @Test func startsInIdle() throws {
        let item = Labs.newSpecimenEstimate("code-983", name: "name-130")
        #expect(item.status == Labs.SpecimenEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newSpecimenEstimate("code-983", name: "name-130")
        try item.moveTo(Labs.SpecimenEstimateStatus.stopped)
        #expect(item.status == Labs.SpecimenEstimateStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newSpecimenEstimate("code-983", name: "name-130")
        item.status = Labs.SpecimenEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenEstimateStatus.idle) }
    }
}
