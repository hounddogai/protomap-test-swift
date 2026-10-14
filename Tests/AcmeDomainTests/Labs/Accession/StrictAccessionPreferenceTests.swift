@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictAccessionPreferenceTests {
    @Test func startsInIdle() throws {
        let item = Labs.newStrictAccessionPreference("code-6", label: "label-39")
        #expect(item.status == Labs.StrictAccessionPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newStrictAccessionPreference("code-6", label: "label-39")
        try item.moveTo(Labs.StrictAccessionPreferenceStatus.warming)
        #expect(item.status == Labs.StrictAccessionPreferenceStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newStrictAccessionPreference("code-6", label: "label-39")
        item.status = Labs.StrictAccessionPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictAccessionPreferenceStatus.idle) }
    }
}
