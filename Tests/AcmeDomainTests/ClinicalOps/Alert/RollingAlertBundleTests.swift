@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertBundleTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newRollingAlertBundle("code-970", name: "name-590")
        #expect(item.status == ClinicalOps.RollingAlertBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newRollingAlertBundle("code-970", name: "name-590")
        try item.moveTo(ClinicalOps.RollingAlertBundleStatus.revoked)
        #expect(item.status == ClinicalOps.RollingAlertBundleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newRollingAlertBundle("code-970", name: "name-590")
        item.status = ClinicalOps.RollingAlertBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingAlertBundleStatus.requested) }
    }
}
