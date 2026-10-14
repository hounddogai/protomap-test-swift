@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultAccessionReservationTests {
    @Test func startsInIdle() throws {
        let item = Labs.newDefaultAccessionReservation("code-201", title: "title-430")
        #expect(item.status == Labs.DefaultAccessionReservationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newDefaultAccessionReservation("code-201", title: "title-430")
        try item.moveTo(Labs.DefaultAccessionReservationStatus.ready)
        #expect(item.status == Labs.DefaultAccessionReservationStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newDefaultAccessionReservation("code-201", title: "title-430")
        item.status = Labs.DefaultAccessionReservationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultAccessionReservationStatus.idle) }
    }
}
