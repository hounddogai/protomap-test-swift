@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedSlotForecastTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newCappedSlotForecast("code-875", name: "name-182")
        #expect(item.status == Referrals.CappedSlotForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newCappedSlotForecast("code-875", name: "name-182")
        try item.moveTo(Referrals.CappedSlotForecastStatus.approved)
        #expect(item.status == Referrals.CappedSlotForecastStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newCappedSlotForecast("code-875", name: "name-182")
        item.status = Referrals.CappedSlotForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedSlotForecastStatus.proposed) }
    }
}
