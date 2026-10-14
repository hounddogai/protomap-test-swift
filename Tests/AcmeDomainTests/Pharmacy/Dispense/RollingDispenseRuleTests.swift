@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingDispenseRuleTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newRollingDispenseRule("code-932", label: "label-643")
        #expect(item.status == Pharmacy.RollingDispenseRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newRollingDispenseRule("code-932", label: "label-643")
        try item.moveTo(Pharmacy.RollingDispenseRuleStatus.running)
        #expect(item.status == Pharmacy.RollingDispenseRuleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newRollingDispenseRule("code-932", label: "label-643")
        item.status = Pharmacy.RollingDispenseRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingDispenseRuleStatus.new) }
    }
}
