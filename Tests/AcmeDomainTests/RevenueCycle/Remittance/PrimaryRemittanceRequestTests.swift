@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceRequestTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newPrimaryRemittanceRequest("code-44", title: "title-156")
        #expect(item.status == RevenueCycle.PrimaryRemittanceRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newPrimaryRemittanceRequest("code-44", title: "title-156")
        try item.moveTo(RevenueCycle.PrimaryRemittanceRequestStatus.reopened)
        #expect(item.status == RevenueCycle.PrimaryRemittanceRequestStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newPrimaryRemittanceRequest("code-44", title: "title-156")
        item.status = RevenueCycle.PrimaryRemittanceRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PrimaryRemittanceRequestStatus.`open`) }
    }
}
