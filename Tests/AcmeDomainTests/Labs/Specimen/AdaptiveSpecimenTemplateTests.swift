@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenTemplateTests {
    @Test func startsInIdle() throws {
        let item = Labs.newAdaptiveSpecimenTemplate("code-866", title: "title-58")
        #expect(item.status == Labs.AdaptiveSpecimenTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newAdaptiveSpecimenTemplate("code-866", title: "title-58")
        try item.moveTo(Labs.AdaptiveSpecimenTemplateStatus.stopped)
        #expect(item.status == Labs.AdaptiveSpecimenTemplateStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newAdaptiveSpecimenTemplate("code-866", title: "title-58")
        item.status = Labs.AdaptiveSpecimenTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveSpecimenTemplateStatus.idle) }
    }
}
