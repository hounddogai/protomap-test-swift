@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedHandoffMappingTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newCappedHandoffMapping("code-612", name: "name-518")
        #expect(item.status == ClinicalOps.CappedHandoffMappingStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newCappedHandoffMapping("code-612", name: "name-518")
        try item.moveTo(ClinicalOps.CappedHandoffMappingStatus.resolved)
        #expect(item.status == ClinicalOps.CappedHandoffMappingStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newCappedHandoffMapping("code-612", name: "name-518")
        item.status = ClinicalOps.CappedHandoffMappingStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedHandoffMappingStatus.`open`) }
    }
}
