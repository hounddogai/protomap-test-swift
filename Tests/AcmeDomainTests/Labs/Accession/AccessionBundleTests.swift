@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionBundleTests {
    @Test func startsInIdle() throws {
        let item = Labs.newAccessionBundle("code-502", label: "label-888")
        #expect(item.status == Labs.AccessionBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newAccessionBundle("code-502", label: "label-888")
        try item.moveTo(Labs.AccessionBundleStatus.warming)
        #expect(item.status == Labs.AccessionBundleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newAccessionBundle("code-502", label: "label-888")
        item.status = Labs.AccessionBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionBundleStatus.idle) }
    }
}
