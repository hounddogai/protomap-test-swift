@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveAccessionBundleTests {
    @Test func startsInRequested() throws {
        let item = Labs.newAdaptiveAccessionBundle("code-106", label: "label-395")
        #expect(item.status == Labs.AdaptiveAccessionBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newAdaptiveAccessionBundle("code-106", label: "label-395")
        try item.moveTo(Labs.AdaptiveAccessionBundleStatus.granted)
        #expect(item.status == Labs.AdaptiveAccessionBundleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newAdaptiveAccessionBundle("code-106", label: "label-395")
        item.status = Labs.AdaptiveAccessionBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveAccessionBundleStatus.requested) }
    }
}
