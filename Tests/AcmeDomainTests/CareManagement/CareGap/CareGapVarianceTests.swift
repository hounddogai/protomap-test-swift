@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapVarianceTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newCareGapVariance("code-164", title: "title-38")
        #expect(item.status == CareManagement.CareGapVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newCareGapVariance("code-164", title: "title-38")
        try item.moveTo(CareManagement.CareGapVarianceStatus.rejected)
        #expect(item.status == CareManagement.CareGapVarianceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newCareGapVariance("code-164", title: "title-38")
        item.status = CareManagement.CareGapVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapVarianceStatus.proposed) }
    }
}
