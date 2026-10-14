@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolEstimateTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newCareProtocolEstimate("code-737", label: "label-178")
        #expect(item.status == Imaging.CareProtocolEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newCareProtocolEstimate("code-737", label: "label-178")
        try item.moveTo(Imaging.CareProtocolEstimateStatus.expired)
        #expect(item.status == Imaging.CareProtocolEstimateStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newCareProtocolEstimate("code-737", label: "label-178")
        item.status = Imaging.CareProtocolEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolEstimateStatus.requested) }
    }
}
