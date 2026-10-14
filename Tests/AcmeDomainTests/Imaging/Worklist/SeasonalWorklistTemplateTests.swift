@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalWorklistTemplateTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newSeasonalWorklistTemplate("code-735", title: "title-719")
        #expect(item.status == Imaging.SeasonalWorklistTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Imaging.newSeasonalWorklistTemplate("code-735", title: "title-719")
        try item.moveTo(Imaging.SeasonalWorklistTemplateStatus.archived)
        #expect(item.status == Imaging.SeasonalWorklistTemplateStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newSeasonalWorklistTemplate("code-735", title: "title-719")
        item.status = Imaging.SeasonalWorklistTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalWorklistTemplateStatus.`open`) }
    }
}
