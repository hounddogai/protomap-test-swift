@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledStudyRuleTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newScheduledStudyRule("code-135", title: "title-567")
        #expect(item.status == Imaging.ScheduledStudyRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newScheduledStudyRule("code-135", title: "title-567")
        try item.moveTo(Imaging.ScheduledStudyRuleStatus.resolved)
        #expect(item.status == Imaging.ScheduledStudyRuleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newScheduledStudyRule("code-135", title: "title-567")
        item.status = Imaging.ScheduledStudyRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledStudyRuleStatus.`open`) }
    }
}
