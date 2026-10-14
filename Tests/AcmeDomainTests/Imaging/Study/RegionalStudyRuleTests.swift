@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyRuleTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newRegionalStudyRule("code-877", title: "title-332")
        #expect(item.status == Imaging.RegionalStudyRuleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Imaging.newRegionalStudyRule("code-877", title: "title-332")
        try item.moveTo(Imaging.RegionalStudyRuleStatus.retired)
        #expect(item.status == Imaging.RegionalStudyRuleStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newRegionalStudyRule("code-877", title: "title-332")
        item.status = Imaging.RegionalStudyRuleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalStudyRuleStatus.created) }
    }
}
