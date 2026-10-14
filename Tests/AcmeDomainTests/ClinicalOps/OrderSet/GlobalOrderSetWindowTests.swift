@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalOrderSetWindowTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newGlobalOrderSetWindow("code-103", name: "name-137")
        #expect(item.status == ClinicalOps.GlobalOrderSetWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newGlobalOrderSetWindow("code-103", name: "name-137")
        try item.moveTo(ClinicalOps.GlobalOrderSetWindowStatus.validated)
        #expect(item.status == ClinicalOps.GlobalOrderSetWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newGlobalOrderSetWindow("code-103", name: "name-137")
        item.status = ClinicalOps.GlobalOrderSetWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalOrderSetWindowStatus.created) }
    }
}
