@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningBundleTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newCleaningBundle("code-532", title: "title-543")
        #expect(item.status == BedManagement.CleaningBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newCleaningBundle("code-532", title: "title-543")
        try item.moveTo(BedManagement.CleaningBundleStatus.revoked)
        #expect(item.status == BedManagement.CleaningBundleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newCleaningBundle("code-532", title: "title-543")
        item.status = BedManagement.CleaningBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningBundleStatus.requested) }
    }
}
