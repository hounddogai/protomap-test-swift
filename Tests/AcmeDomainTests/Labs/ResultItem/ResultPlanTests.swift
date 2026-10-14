@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultPlanTests {
    @Test func startsInRequested() throws {
        let item = Labs.newResultPlan("code-447", name: "name-740")
        #expect(item.status == Labs.ResultPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newResultPlan("code-447", name: "name-740")
        try item.moveTo(Labs.ResultPlanStatus.granted)
        #expect(item.status == Labs.ResultPlanStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newResultPlan("code-447", name: "name-740")
        item.status = Labs.ResultPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultPlanStatus.requested) }
    }
}
