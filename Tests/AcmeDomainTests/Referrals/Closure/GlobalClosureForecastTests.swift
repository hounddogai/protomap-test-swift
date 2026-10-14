@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalClosureForecastTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newGlobalClosureForecast("code-350", title: "title-483")
        #expect(item.status == Referrals.GlobalClosureForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newGlobalClosureForecast("code-350", title: "title-483")
        try item.moveTo(Referrals.GlobalClosureForecastStatus.validated)
        #expect(item.status == Referrals.GlobalClosureForecastStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newGlobalClosureForecast("code-350", title: "title-483")
        item.status = Referrals.GlobalClosureForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalClosureForecastStatus.created) }
    }
}
