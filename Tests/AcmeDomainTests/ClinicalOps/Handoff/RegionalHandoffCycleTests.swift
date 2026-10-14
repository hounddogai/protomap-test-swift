@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalHandoffCycleTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newRegionalHandoffCycle("code-757", title: "title-498")
        #expect(item.status == ClinicalOps.RegionalHandoffCycleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newRegionalHandoffCycle("code-757", title: "title-498")
        try item.moveTo(ClinicalOps.RegionalHandoffCycleStatus.resolved)
        #expect(item.status == ClinicalOps.RegionalHandoffCycleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newRegionalHandoffCycle("code-757", title: "title-498")
        item.status = ClinicalOps.RegionalHandoffCycleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalHandoffCycleStatus.`open`) }
    }
}
