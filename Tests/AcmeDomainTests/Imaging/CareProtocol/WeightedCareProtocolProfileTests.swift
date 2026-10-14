@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedCareProtocolProfileTests {
    @Test func startsInNew() throws {
        let item = Imaging.newWeightedCareProtocolProfile("code-454", title: "title-536")
        #expect(item.status == Imaging.WeightedCareProtocolProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newWeightedCareProtocolProfile("code-454", title: "title-536")
        try item.moveTo(Imaging.WeightedCareProtocolProfileStatus.queued)
        #expect(item.status == Imaging.WeightedCareProtocolProfileStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newWeightedCareProtocolProfile("code-454", title: "title-536")
        item.status = Imaging.WeightedCareProtocolProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedCareProtocolProfileStatus.new) }
    }
}
