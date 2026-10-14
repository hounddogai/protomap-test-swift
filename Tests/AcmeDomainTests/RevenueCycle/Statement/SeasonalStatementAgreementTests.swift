@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalStatementAgreementTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newSeasonalStatementAgreement("code-866", name: "name-728")
        #expect(item.status == RevenueCycle.SeasonalStatementAgreementStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = RevenueCycle.newSeasonalStatementAgreement("code-866", name: "name-728")
        try item.moveTo(RevenueCycle.SeasonalStatementAgreementStatus.cancelled)
        #expect(item.status == RevenueCycle.SeasonalStatementAgreementStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newSeasonalStatementAgreement("code-866", name: "name-728")
        item.status = RevenueCycle.SeasonalStatementAgreementStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.SeasonalStatementAgreementStatus.planned) }
    }
}
