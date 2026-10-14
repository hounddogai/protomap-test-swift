@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyPlanTests {
    @Test func startsInNew() throws {
        let item = Imaging.newStudyPlan("code-204", name: "name-397")
        #expect(item.status == Imaging.StudyPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Imaging.newStudyPlan("code-204", name: "name-397")
        try item.moveTo(Imaging.StudyPlanStatus.failed)
        #expect(item.status == Imaging.StudyPlanStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newStudyPlan("code-204", name: "name-397")
        item.status = Imaging.StudyPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyPlanStatus.new) }
    }
}
