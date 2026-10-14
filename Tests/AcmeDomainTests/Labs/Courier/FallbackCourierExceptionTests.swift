@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierExceptionTests {
    @Test func startsInCreated() throws {
        let item = Labs.newFallbackCourierException("code-86", title: "title-965")
        #expect(item.status == Labs.FallbackCourierExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newFallbackCourierException("code-86", title: "title-965")
        try item.moveTo(Labs.FallbackCourierExceptionStatus.validated)
        #expect(item.status == Labs.FallbackCourierExceptionStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newFallbackCourierException("code-86", title: "title-965")
        item.status = Labs.FallbackCourierExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackCourierExceptionStatus.created) }
    }
}
