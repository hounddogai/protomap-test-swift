@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenThresholdTests {
    @Test func startsInIdle() throws {
        let item = Labs.newSpecimenThreshold("code-970", title: "title-32")
        #expect(item.status == Labs.SpecimenThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newSpecimenThreshold("code-970", title: "title-32")
        try item.moveTo(Labs.SpecimenThresholdStatus.ready)
        #expect(item.status == Labs.SpecimenThresholdStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newSpecimenThreshold("code-970", title: "title-32")
        item.status = Labs.SpecimenThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenThresholdStatus.idle) }
    }
}
