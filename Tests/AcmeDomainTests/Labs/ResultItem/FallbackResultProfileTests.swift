@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackResultProfileTests {
    @Test func startsInIdle() throws {
        let item = Labs.newFallbackResultProfile("code-828", title: "title-478")
        #expect(item.status == Labs.FallbackResultProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newFallbackResultProfile("code-828", title: "title-478")
        try item.moveTo(Labs.FallbackResultProfileStatus.ready)
        #expect(item.status == Labs.FallbackResultProfileStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newFallbackResultProfile("code-828", title: "title-478")
        item.status = Labs.FallbackResultProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackResultProfileStatus.idle) }
    }
}
