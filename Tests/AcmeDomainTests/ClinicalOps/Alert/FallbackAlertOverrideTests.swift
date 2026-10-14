@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackAlertOverrideTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newFallbackAlertOverride("code-929", title: "title-599")
        #expect(item.status == ClinicalOps.FallbackAlertOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newFallbackAlertOverride("code-929", title: "title-599")
        try item.moveTo(ClinicalOps.FallbackAlertOverrideStatus.suspended)
        #expect(item.status == ClinicalOps.FallbackAlertOverrideStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newFallbackAlertOverride("code-929", title: "title-599")
        item.status = ClinicalOps.FallbackAlertOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackAlertOverrideStatus.draft) }
    }
}
