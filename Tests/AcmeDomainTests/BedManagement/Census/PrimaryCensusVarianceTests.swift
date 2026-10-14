@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusVarianceTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newPrimaryCensusVariance("code-566", label: "label-251")
        #expect(item.status == BedManagement.PrimaryCensusVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newPrimaryCensusVariance("code-566", label: "label-251")
        try item.moveTo(BedManagement.PrimaryCensusVarianceStatus.published)
        #expect(item.status == BedManagement.PrimaryCensusVarianceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newPrimaryCensusVariance("code-566", label: "label-251")
        item.status = BedManagement.PrimaryCensusVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryCensusVarianceStatus.created) }
    }
}
