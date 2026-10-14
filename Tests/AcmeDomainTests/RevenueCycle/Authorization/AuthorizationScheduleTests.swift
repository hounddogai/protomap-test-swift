@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationScheduleTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newAuthorizationSchedule("code-979", label: "label-773")
        #expect(item.status == RevenueCycle.AuthorizationScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newAuthorizationSchedule("code-979", label: "label-773")
        try item.moveTo(RevenueCycle.AuthorizationScheduleStatus.inReview)
        #expect(item.status == RevenueCycle.AuthorizationScheduleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newAuthorizationSchedule("code-979", label: "label-773")
        item.status = RevenueCycle.AuthorizationScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationScheduleStatus.`open`) }
    }
}
