@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceVarianceTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newPrimaryRemittanceVariance("code-430", title: "title-576")
        #expect(item.status == RevenueCycle.PrimaryRemittanceVarianceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newPrimaryRemittanceVariance("code-430", title: "title-576")
        try item.moveTo(RevenueCycle.PrimaryRemittanceVarianceStatus.reopened)
        #expect(item.status == RevenueCycle.PrimaryRemittanceVarianceStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newPrimaryRemittanceVariance("code-430", title: "title-576")
        item.status = RevenueCycle.PrimaryRemittanceVarianceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PrimaryRemittanceVarianceStatus.`open`) }
    }
}
