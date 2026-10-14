@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalTransferPolicyTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newSeasonalTransferPolicy("code-856", name: "name-218")
        #expect(item.status == BedManagement.SeasonalTransferPolicyStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newSeasonalTransferPolicy("code-856", name: "name-218")
        try item.moveTo(BedManagement.SeasonalTransferPolicyStatus.granted)
        #expect(item.status == BedManagement.SeasonalTransferPolicyStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newSeasonalTransferPolicy("code-856", name: "name-218")
        item.status = BedManagement.SeasonalTransferPolicyStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.SeasonalTransferPolicyStatus.requested) }
    }
}
