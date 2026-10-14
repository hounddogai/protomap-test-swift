@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalOrderSetOverrideTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newRegionalOrderSetOverride("code-920", label: "label-308")
        #expect(item.status == ClinicalOps.RegionalOrderSetOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newRegionalOrderSetOverride("code-920", label: "label-308")
        try item.moveTo(ClinicalOps.RegionalOrderSetOverrideStatus.revoked)
        #expect(item.status == ClinicalOps.RegionalOrderSetOverrideStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newRegionalOrderSetOverride("code-920", label: "label-308")
        item.status = ClinicalOps.RegionalOrderSetOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalOrderSetOverrideStatus.requested) }
    }
}
