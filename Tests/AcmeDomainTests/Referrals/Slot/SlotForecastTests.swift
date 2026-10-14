@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotForecastTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newSlotForecast("code-920", name: "name-661")
        #expect(item.status == Referrals.SlotForecastStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newSlotForecast("code-920", name: "name-661")
        try item.moveTo(Referrals.SlotForecastStatus.reopened)
        #expect(item.status == Referrals.SlotForecastStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newSlotForecast("code-920", name: "name-661")
        item.status = Referrals.SlotForecastStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotForecastStatus.`open`) }
    }
}
