@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenScheduleTests {
    @Test func startsInCreated() throws {
        let item = Labs.newAdaptiveSpecimenSchedule("code-204", name: "name-491")
        #expect(item.status == Labs.AdaptiveSpecimenScheduleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newAdaptiveSpecimenSchedule("code-204", name: "name-491")
        try item.moveTo(Labs.AdaptiveSpecimenScheduleStatus.validated)
        #expect(item.status == Labs.AdaptiveSpecimenScheduleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newAdaptiveSpecimenSchedule("code-204", name: "name-491")
        item.status = Labs.AdaptiveSpecimenScheduleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveSpecimenScheduleStatus.created) }
    }
}
