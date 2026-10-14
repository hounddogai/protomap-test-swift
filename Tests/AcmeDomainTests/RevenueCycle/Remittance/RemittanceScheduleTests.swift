@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceScheduleTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newRemittanceSchedule("code-615", title: "title-715")
        #expect(item.status == RevenueCycle.RemittanceScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newRemittanceSchedule("code-615", title: "title-715")
        try item.moveTo(RevenueCycle.RemittanceScheduleStatus.inProgress)
        #expect(item.status == RevenueCycle.RemittanceScheduleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newRemittanceSchedule("code-615", title: "title-715")
        item.status = RevenueCycle.RemittanceScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceScheduleStatus.planned) }
    }
}
