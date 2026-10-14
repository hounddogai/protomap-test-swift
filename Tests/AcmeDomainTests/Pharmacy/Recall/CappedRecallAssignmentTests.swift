@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedRecallAssignmentTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newCappedRecallAssignment("code-268", title: "title-356")
        #expect(item.status == Pharmacy.CappedRecallAssignmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newCappedRecallAssignment("code-268", title: "title-356")
        try item.moveTo(Pharmacy.CappedRecallAssignmentStatus.running)
        #expect(item.status == Pharmacy.CappedRecallAssignmentStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newCappedRecallAssignment("code-268", title: "title-356")
        item.status = Pharmacy.CappedRecallAssignmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedRecallAssignmentStatus.new) }
    }
}
