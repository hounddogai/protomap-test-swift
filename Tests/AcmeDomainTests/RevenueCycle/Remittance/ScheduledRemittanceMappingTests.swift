@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledRemittanceMappingTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newScheduledRemittanceMapping("code-715", name: "name-482")
        #expect(item.status == RevenueCycle.ScheduledRemittanceMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newScheduledRemittanceMapping("code-715", name: "name-482")
        try item.moveTo(RevenueCycle.ScheduledRemittanceMappingStatus.scheduled)
        #expect(item.status == RevenueCycle.ScheduledRemittanceMappingStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newScheduledRemittanceMapping("code-715", name: "name-482")
        item.status = RevenueCycle.ScheduledRemittanceMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledRemittanceMappingStatus.planned) }
    }
}
