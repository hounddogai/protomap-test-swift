@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionPlanTests {
    @Test func startsInRequested() throws {
        let item = Labs.newAccessionPlan("code-13", title: "title-985")
        #expect(item.status == Labs.AccessionPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newAccessionPlan("code-13", title: "title-985")
        try item.moveTo(Labs.AccessionPlanStatus.granted)
        #expect(item.status == Labs.AccessionPlanStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newAccessionPlan("code-13", title: "title-985")
        item.status = Labs.AccessionPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionPlanStatus.requested) }
    }
}
