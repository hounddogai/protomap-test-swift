@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveDispenseRuleTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newAdaptiveDispenseRule("code-736", title: "title-584")
        #expect(item.status == Pharmacy.AdaptiveDispenseRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newAdaptiveDispenseRule("code-736", title: "title-584")
        try item.moveTo(Pharmacy.AdaptiveDispenseRuleStatus.queued)
        #expect(item.status == Pharmacy.AdaptiveDispenseRuleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newAdaptiveDispenseRule("code-736", title: "title-584")
        item.status = Pharmacy.AdaptiveDispenseRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveDispenseRuleStatus.new) }
    }
}
