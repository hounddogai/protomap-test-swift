@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittancePlanTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newPrimaryRemittancePlan("code-832", name: "name-978")
        #expect(item.status == RevenueCycle.PrimaryRemittancePlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = RevenueCycle.newPrimaryRemittancePlan("code-832", name: "name-978")
        try item.moveTo(RevenueCycle.PrimaryRemittancePlanStatus.cancelled)
        #expect(item.status == RevenueCycle.PrimaryRemittancePlanStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newPrimaryRemittancePlan("code-832", name: "name-978")
        item.status = RevenueCycle.PrimaryRemittancePlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PrimaryRemittancePlanStatus.planned) }
    }
}
