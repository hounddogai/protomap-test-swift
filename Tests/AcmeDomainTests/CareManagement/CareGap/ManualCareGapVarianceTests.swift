@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapVarianceTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newManualCareGapVariance("code-916", title: "title-486")
        #expect(item.status == CareManagement.ManualCareGapVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newManualCareGapVariance("code-916", title: "title-486")
        try item.moveTo(CareManagement.ManualCareGapVarianceStatus.published)
        #expect(item.status == CareManagement.ManualCareGapVarianceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newManualCareGapVariance("code-916", title: "title-486")
        item.status = CareManagement.ManualCareGapVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualCareGapVarianceStatus.created) }
    }
}
