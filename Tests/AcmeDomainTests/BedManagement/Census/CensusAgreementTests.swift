@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusAgreementTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newCensusAgreement("code-330", title: "title-540")
        #expect(item.status == BedManagement.CensusAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newCensusAgreement("code-330", title: "title-540")
        try item.moveTo(BedManagement.CensusAgreementStatus.validated)
        #expect(item.status == BedManagement.CensusAgreementStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newCensusAgreement("code-330", title: "title-540")
        item.status = BedManagement.CensusAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusAgreementStatus.created) }
    }
}
