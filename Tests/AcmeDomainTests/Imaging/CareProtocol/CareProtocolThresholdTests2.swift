@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolThresholdTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newCareProtocolThreshold("code-580", name: "name-471")
        #expect(item.status == Imaging.CareProtocolThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newCareProtocolThreshold("code-580", name: "name-471")
        try item.moveTo(Imaging.CareProtocolThresholdStatus.rejected)
        #expect(item.status == Imaging.CareProtocolThresholdStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newCareProtocolThreshold("code-580", name: "name-471")
        item.status = Imaging.CareProtocolThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolThresholdStatus.proposed) }
    }
}
