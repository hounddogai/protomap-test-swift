@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackSpecimenBundleTests {
    @Test func startsInIdle() throws {
        let item = Labs.newFallbackSpecimenBundle("code-336", label: "label-436")
        #expect(item.status == Labs.FallbackSpecimenBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newFallbackSpecimenBundle("code-336", label: "label-436")
        try item.moveTo(Labs.FallbackSpecimenBundleStatus.draining)
        #expect(item.status == Labs.FallbackSpecimenBundleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newFallbackSpecimenBundle("code-336", label: "label-436")
        item.status = Labs.FallbackSpecimenBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackSpecimenBundleStatus.idle) }
    }
}
