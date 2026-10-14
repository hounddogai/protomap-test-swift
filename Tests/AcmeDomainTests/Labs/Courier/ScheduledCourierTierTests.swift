@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledCourierTierTests {
    @Test func startsInRequested() throws {
        let item = Labs.newScheduledCourierTier("code-342", title: "title-274")
        #expect(item.status == Labs.ScheduledCourierTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newScheduledCourierTier("code-342", title: "title-274")
        try item.moveTo(Labs.ScheduledCourierTierStatus.expired)
        #expect(item.status == Labs.ScheduledCourierTierStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newScheduledCourierTier("code-342", title: "title-274")
        item.status = Labs.ScheduledCourierTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledCourierTierStatus.requested) }
    }
}
