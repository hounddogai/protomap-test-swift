@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeScheduleTests {
    @Test func startsInNew() throws {
        let item = Labs.newLenientReferenceRangeSchedule("code-623", title: "title-501")
        #expect(item.status == Labs.LenientReferenceRangeScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Labs.newLenientReferenceRangeSchedule("code-623", title: "title-501")
        try item.moveTo(Labs.LenientReferenceRangeScheduleStatus.failed)
        #expect(item.status == Labs.LenientReferenceRangeScheduleStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newLenientReferenceRangeSchedule("code-623", title: "title-501")
        item.status = Labs.LenientReferenceRangeScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientReferenceRangeScheduleStatus.new) }
    }
}
