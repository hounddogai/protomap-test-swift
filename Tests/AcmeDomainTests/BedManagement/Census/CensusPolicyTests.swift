@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusPolicyTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newCensusPolicy("code-323", name: "name-447")
        #expect(item.status == BedManagement.CensusPolicyStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = BedManagement.newCensusPolicy("code-323", name: "name-447")
        try item.moveTo(BedManagement.CensusPolicyStatus.expired)
        #expect(item.status == BedManagement.CensusPolicyStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newCensusPolicy("code-323", name: "name-447")
        item.status = BedManagement.CensusPolicyStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusPolicyStatus.requested) }
    }
}
