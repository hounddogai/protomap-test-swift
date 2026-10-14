@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskVarianceTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newTaskVariance("code-56", title: "title-980")
        #expect(item.status == ClinicalOps.TaskVarianceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newTaskVariance("code-56", title: "title-980")
        try item.moveTo(ClinicalOps.TaskVarianceStatus.granted)
        #expect(item.status == ClinicalOps.TaskVarianceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newTaskVariance("code-56", title: "title-980")
        item.status = ClinicalOps.TaskVarianceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskVarianceStatus.requested) }
    }
}
