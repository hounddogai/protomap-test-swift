@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyEstimateTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newStudyEstimate("code-354", name: "name-691")
        #expect(item.status == Imaging.StudyEstimateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newStudyEstimate("code-354", name: "name-691")
        try item.moveTo(Imaging.StudyEstimateStatus.approved)
        #expect(item.status == Imaging.StudyEstimateStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newStudyEstimate("code-354", name: "name-691")
        item.status = Imaging.StudyEstimateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyEstimateStatus.proposed) }
    }
}
