@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyClaimTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newStudyClaim("code-433", label: "label-520")
        #expect(item.status == Imaging.StudyClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newStudyClaim("code-433", label: "label-520")
        try item.moveTo(Imaging.StudyClaimStatus.withdrawn)
        #expect(item.status == Imaging.StudyClaimStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newStudyClaim("code-433", label: "label-520")
        item.status = Imaging.StudyClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyClaimStatus.proposed) }
    }
}
