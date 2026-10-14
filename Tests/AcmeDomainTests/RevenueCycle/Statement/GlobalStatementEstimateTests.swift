@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalStatementEstimateTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newGlobalStatementEstimate("code-110", label: "label-694")
        #expect(item.status == RevenueCycle.GlobalStatementEstimateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newGlobalStatementEstimate("code-110", label: "label-694")
        try item.moveTo(RevenueCycle.GlobalStatementEstimateStatus.published)
        #expect(item.status == RevenueCycle.GlobalStatementEstimateStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newGlobalStatementEstimate("code-110", label: "label-694")
        item.status = RevenueCycle.GlobalStatementEstimateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalStatementEstimateStatus.created) }
    }
}
