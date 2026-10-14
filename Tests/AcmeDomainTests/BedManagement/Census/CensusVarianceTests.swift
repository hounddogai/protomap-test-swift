@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusVarianceTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newCensusVariance("code-383", title: "title-10")
        #expect(item.status == BedManagement.CensusVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = BedManagement.newCensusVariance("code-383", title: "title-10")
        try item.moveTo(BedManagement.CensusVarianceStatus.retired)
        #expect(item.status == BedManagement.CensusVarianceStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newCensusVariance("code-383", title: "title-10")
        item.status = BedManagement.CensusVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusVarianceStatus.created) }
    }
}
