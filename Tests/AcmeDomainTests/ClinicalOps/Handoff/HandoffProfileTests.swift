@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffProfileTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newHandoffProfile("code-338", label: "label-243")
        #expect(item.status == ClinicalOps.HandoffProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newHandoffProfile("code-338", label: "label-243")
        try item.moveTo(ClinicalOps.HandoffProfileStatus.published)
        #expect(item.status == ClinicalOps.HandoffProfileStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newHandoffProfile("code-338", label: "label-243")
        item.status = ClinicalOps.HandoffProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffProfileStatus.created) }
    }
}
