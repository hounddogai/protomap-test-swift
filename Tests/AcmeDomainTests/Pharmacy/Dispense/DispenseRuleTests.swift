@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRuleTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newDispenseRule("code-151", name: "name-596")
        #expect(item.status == Pharmacy.DispenseRuleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newDispenseRule("code-151", name: "name-596")
        try item.moveTo(Pharmacy.DispenseRuleStatus.warming)
        #expect(item.status == Pharmacy.DispenseRuleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newDispenseRule("code-151", name: "name-596")
        item.status = Pharmacy.DispenseRuleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseRuleStatus.idle) }
    }
}
