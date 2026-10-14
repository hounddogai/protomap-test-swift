@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionThresholdTests {
    @Test func startsInCreated() throws {
        let item = Labs.newFallbackAccessionThreshold("code-632", name: "name-839")
        #expect(item.status == Labs.FallbackAccessionThresholdStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Labs.newFallbackAccessionThreshold("code-632", name: "name-839")
        try item.moveTo(Labs.FallbackAccessionThresholdStatus.retired)
        #expect(item.status == Labs.FallbackAccessionThresholdStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newFallbackAccessionThreshold("code-632", name: "name-839")
        item.status = Labs.FallbackAccessionThresholdStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackAccessionThresholdStatus.created) }
    }
}
