@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalPriorityAgreementTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newSeasonalPriorityAgreement("code-413", name: "name-576")
        #expect(item.status == Imaging.SeasonalPriorityAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newSeasonalPriorityAgreement("code-413", name: "name-576")
        try item.moveTo(Imaging.SeasonalPriorityAgreementStatus.published)
        #expect(item.status == Imaging.SeasonalPriorityAgreementStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newSeasonalPriorityAgreement("code-413", name: "name-576")
        item.status = Imaging.SeasonalPriorityAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalPriorityAgreementStatus.created) }
    }
}
