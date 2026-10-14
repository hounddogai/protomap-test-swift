@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedCareProtocolVarianceTests {
    @Test func startsInNew() throws {
        let item = Imaging.newWeightedCareProtocolVariance("code-811", title: "title-269")
        #expect(item.status == Imaging.WeightedCareProtocolVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newWeightedCareProtocolVariance("code-811", title: "title-269")
        try item.moveTo(Imaging.WeightedCareProtocolVarianceStatus.queued)
        #expect(item.status == Imaging.WeightedCareProtocolVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newWeightedCareProtocolVariance("code-811", title: "title-269")
        item.status = Imaging.WeightedCareProtocolVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedCareProtocolVarianceStatus.new) }
    }
}
