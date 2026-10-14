@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalHandoffExceptionTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newRegionalHandoffException("code-483", name: "name-376")
        #expect(item.status == ClinicalOps.RegionalHandoffExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newRegionalHandoffException("code-483", name: "name-376")
        try item.moveTo(ClinicalOps.RegionalHandoffExceptionStatus.validated)
        #expect(item.status == ClinicalOps.RegionalHandoffExceptionStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newRegionalHandoffException("code-483", name: "name-376")
        item.status = ClinicalOps.RegionalHandoffExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalHandoffExceptionStatus.created) }
    }
}
