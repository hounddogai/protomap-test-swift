@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittancePlanTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRemittancePlan("code-396", title: "title-632")
        #expect(item.status == RevenueCycle.RemittancePlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newRemittancePlan("code-396", title: "title-632")
        try item.moveTo(RevenueCycle.RemittancePlanStatus.done)
        #expect(item.status == RevenueCycle.RemittancePlanStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRemittancePlan("code-396", title: "title-632")
        item.status = RevenueCycle.RemittancePlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittancePlanStatus.new) }
    }
}
