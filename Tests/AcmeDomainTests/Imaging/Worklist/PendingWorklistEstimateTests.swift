@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistEstimateTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newPendingWorklistEstimate("code-758", name: "name-859")
        #expect(item.status == Imaging.PendingWorklistEstimateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newPendingWorklistEstimate("code-758", name: "name-859")
        try item.moveTo(Imaging.PendingWorklistEstimateStatus.published)
        #expect(item.status == Imaging.PendingWorklistEstimateStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newPendingWorklistEstimate("code-758", name: "name-859")
        item.status = Imaging.PendingWorklistEstimateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingWorklistEstimateStatus.created) }
    }
}
