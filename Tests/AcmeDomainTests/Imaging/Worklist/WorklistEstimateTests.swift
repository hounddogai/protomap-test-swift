@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistEstimateTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newWorklistEstimate("code-251", name: "name-182")
        #expect(item.status == Imaging.WorklistEstimateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newWorklistEstimate("code-251", name: "name-182")
        try item.moveTo(Imaging.WorklistEstimateStatus.validated)
        #expect(item.status == Imaging.WorklistEstimateStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newWorklistEstimate("code-251", name: "name-182")
        item.status = Imaging.WorklistEstimateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistEstimateStatus.created) }
    }
}
