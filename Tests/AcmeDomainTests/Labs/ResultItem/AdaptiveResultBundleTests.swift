@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultBundleTests {
    @Test func startsInCreated() throws {
        let item = Labs.newAdaptiveResultBundle("code-7", name: "name-525")
        #expect(item.status == Labs.AdaptiveResultBundleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newAdaptiveResultBundle("code-7", name: "name-525")
        try item.moveTo(Labs.AdaptiveResultBundleStatus.validated)
        #expect(item.status == Labs.AdaptiveResultBundleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newAdaptiveResultBundle("code-7", name: "name-525")
        item.status = Labs.AdaptiveResultBundleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveResultBundleStatus.created) }
    }
}
