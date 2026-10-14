@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyPolicyTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newStudyPolicy("code-769", title: "title-930")
        #expect(item.status == Imaging.StudyPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newStudyPolicy("code-769", title: "title-930")
        try item.moveTo(Imaging.StudyPolicyStatus.withdrawn)
        #expect(item.status == Imaging.StudyPolicyStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newStudyPolicy("code-769", title: "title-930")
        item.status = Imaging.StudyPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyPolicyStatus.proposed) }
    }
}
