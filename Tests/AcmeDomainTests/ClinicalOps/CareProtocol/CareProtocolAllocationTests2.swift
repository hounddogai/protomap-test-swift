@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolAllocationTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newCareProtocolAllocation("code-832", name: "name-611")
        #expect(item.status == ClinicalOps.CareProtocolAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newCareProtocolAllocation("code-832", name: "name-611")
        try item.moveTo(ClinicalOps.CareProtocolAllocationStatus.resolved)
        #expect(item.status == ClinicalOps.CareProtocolAllocationStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newCareProtocolAllocation("code-832", name: "name-611")
        item.status = ClinicalOps.CareProtocolAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolAllocationStatus.`open`) }
    }
}
