@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalCareProtocolPolicyTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newSeasonalCareProtocolPolicy("code-322", name: "name-809")
        #expect(item.status == Imaging.SeasonalCareProtocolPolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newSeasonalCareProtocolPolicy("code-322", name: "name-809")
        try item.moveTo(Imaging.SeasonalCareProtocolPolicyStatus.cancelled)
        #expect(item.status == Imaging.SeasonalCareProtocolPolicyStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newSeasonalCareProtocolPolicy("code-322", name: "name-809")
        item.status = Imaging.SeasonalCareProtocolPolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalCareProtocolPolicyStatus.planned) }
    }
}
