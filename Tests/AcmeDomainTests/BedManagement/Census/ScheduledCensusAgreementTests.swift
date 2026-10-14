@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusAgreementTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newScheduledCensusAgreement("code-895", name: "name-920")
        #expect(item.status == BedManagement.ScheduledCensusAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newScheduledCensusAgreement("code-895", name: "name-920")
        try item.moveTo(BedManagement.ScheduledCensusAgreementStatus.warming)
        #expect(item.status == BedManagement.ScheduledCensusAgreementStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newScheduledCensusAgreement("code-895", name: "name-920")
        item.status = BedManagement.ScheduledCensusAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCensusAgreementStatus.idle) }
    }
}
