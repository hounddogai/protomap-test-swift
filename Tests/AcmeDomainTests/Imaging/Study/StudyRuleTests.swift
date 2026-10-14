@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyRuleTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newStudyRule("code-802", name: "name-36")
        #expect(item.status == Imaging.StudyRuleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newStudyRule("code-802", name: "name-36")
        try item.moveTo(Imaging.StudyRuleStatus.approved)
        #expect(item.status == Imaging.StudyRuleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newStudyRule("code-802", name: "name-36")
        item.status = Imaging.StudyRuleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyRuleStatus.proposed) }
    }
}
