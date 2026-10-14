@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferVarianceTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newWeightedTransferVariance("code-590", name: "name-252")
        #expect(item.status == BedManagement.WeightedTransferVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newWeightedTransferVariance("code-590", name: "name-252")
        try item.moveTo(BedManagement.WeightedTransferVarianceStatus.published)
        #expect(item.status == BedManagement.WeightedTransferVarianceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newWeightedTransferVariance("code-590", name: "name-252")
        item.status = BedManagement.WeightedTransferVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedTransferVarianceStatus.created) }
    }
}
