@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimQuotaTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newTieredClaimQuota("code-501", name: "name-310")
        #expect(item.status == RevenueCycle.TieredClaimQuotaStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = RevenueCycle.newTieredClaimQuota("code-501", name: "name-310")
        try item.moveTo(RevenueCycle.TieredClaimQuotaStatus.archived)
        #expect(item.status == RevenueCycle.TieredClaimQuotaStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newTieredClaimQuota("code-501", name: "name-310")
        item.status = RevenueCycle.TieredClaimQuotaStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredClaimQuotaStatus.`open`) }
    }
}
