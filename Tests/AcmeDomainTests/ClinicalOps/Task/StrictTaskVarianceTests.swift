@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictTaskVarianceTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newStrictTaskVariance("code-281", name: "name-230")
        #expect(item.status == ClinicalOps.StrictTaskVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newStrictTaskVariance("code-281", name: "name-230")
        try item.moveTo(ClinicalOps.StrictTaskVarianceStatus.scheduled)
        #expect(item.status == ClinicalOps.StrictTaskVarianceStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newStrictTaskVariance("code-281", name: "name-230")
        item.status = ClinicalOps.StrictTaskVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictTaskVarianceStatus.planned) }
    }
}
