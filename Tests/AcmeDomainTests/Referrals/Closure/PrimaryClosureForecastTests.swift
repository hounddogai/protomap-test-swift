@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryClosureForecastTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newPrimaryClosureForecast("code-66", label: "label-259")
        #expect(item.status == Referrals.PrimaryClosureForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newPrimaryClosureForecast("code-66", label: "label-259")
        try item.moveTo(Referrals.PrimaryClosureForecastStatus.rejected)
        #expect(item.status == Referrals.PrimaryClosureForecastStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newPrimaryClosureForecast("code-66", label: "label-259")
        item.status = Referrals.PrimaryClosureForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryClosureForecastStatus.proposed) }
    }
}
