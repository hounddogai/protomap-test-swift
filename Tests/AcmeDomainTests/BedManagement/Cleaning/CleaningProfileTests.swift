@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningProfileTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCleaningProfile("code-143", name: "name-971")
        #expect(item.status == BedManagement.CleaningProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newCleaningProfile("code-143", name: "name-971")
        try item.moveTo(BedManagement.CleaningProfileStatus.draining)
        #expect(item.status == BedManagement.CleaningProfileStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCleaningProfile("code-143", name: "name-971")
        item.status = BedManagement.CleaningProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningProfileStatus.idle) }
    }
}
