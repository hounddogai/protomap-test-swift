@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeVarianceTests {
    @Test func startsInCreated() throws {
        let item = Labs.newLenientReferenceRangeVariance("code-145", title: "title-60")
        #expect(item.status == Labs.LenientReferenceRangeVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Labs.newLenientReferenceRangeVariance("code-145", title: "title-60")
        try item.moveTo(Labs.LenientReferenceRangeVarianceStatus.published)
        #expect(item.status == Labs.LenientReferenceRangeVarianceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newLenientReferenceRangeVariance("code-145", title: "title-60")
        item.status = Labs.LenientReferenceRangeVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientReferenceRangeVarianceStatus.created) }
    }
}
