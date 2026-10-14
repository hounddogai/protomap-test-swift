@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessBudgetTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newSeasonalWitnessBudget("code-379", title: "title-736")
        #expect(item.status == Consent.SeasonalWitnessBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newSeasonalWitnessBudget("code-379", title: "title-736")
        try item.moveTo(Consent.SeasonalWitnessBudgetStatus.scheduled)
        #expect(item.status == Consent.SeasonalWitnessBudgetStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newSeasonalWitnessBudget("code-379", title: "title-736")
        item.status = Consent.SeasonalWitnessBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalWitnessBudgetStatus.planned) }
    }
}
