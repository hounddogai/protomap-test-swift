@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultReferenceRangeVarianceTests {
    @Test func startsInProposed() throws {
        let item = Labs.newDefaultReferenceRangeVariance("code-955", title: "title-372")
        #expect(item.status == Labs.DefaultReferenceRangeVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newDefaultReferenceRangeVariance("code-955", title: "title-372")
        try item.moveTo(Labs.DefaultReferenceRangeVarianceStatus.approved)
        #expect(item.status == Labs.DefaultReferenceRangeVarianceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newDefaultReferenceRangeVariance("code-955", title: "title-372")
        item.status = Labs.DefaultReferenceRangeVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultReferenceRangeVarianceStatus.proposed) }
    }
}
