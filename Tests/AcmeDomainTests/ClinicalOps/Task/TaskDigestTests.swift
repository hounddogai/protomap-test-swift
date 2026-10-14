@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskDigestTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newTaskDigest("code-961", title: "title-402")
        #expect(item.status == ClinicalOps.TaskDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newTaskDigest("code-961", title: "title-402")
        try item.moveTo(ClinicalOps.TaskDigestStatus.validated)
        #expect(item.status == ClinicalOps.TaskDigestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newTaskDigest("code-961", title: "title-402")
        item.status = ClinicalOps.TaskDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TaskDigestStatus.created) }
    }
}
