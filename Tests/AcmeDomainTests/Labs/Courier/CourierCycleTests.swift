@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierCycleTests {
    @Test func startsInOpen() throws {
        let item = Labs.newCourierCycle("code-406", name: "name-195")
        #expect(item.status == Labs.CourierCycleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newCourierCycle("code-406", name: "name-195")
        try item.moveTo(Labs.CourierCycleStatus.inReview)
        #expect(item.status == Labs.CourierCycleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newCourierCycle("code-406", name: "name-195")
        item.status = Labs.CourierCycleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierCycleStatus.`open`) }
    }
}
