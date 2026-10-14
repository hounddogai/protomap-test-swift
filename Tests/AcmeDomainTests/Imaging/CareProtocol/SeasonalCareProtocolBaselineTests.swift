@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalCareProtocolBaselineTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newSeasonalCareProtocolBaseline("code-924", name: "name-329")
        #expect(item.status == Imaging.SeasonalCareProtocolBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newSeasonalCareProtocolBaseline("code-924", name: "name-329")
        try item.moveTo(Imaging.SeasonalCareProtocolBaselineStatus.validated)
        #expect(item.status == Imaging.SeasonalCareProtocolBaselineStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newSeasonalCareProtocolBaseline("code-924", name: "name-329")
        item.status = Imaging.SeasonalCareProtocolBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalCareProtocolBaselineStatus.created) }
    }
}
