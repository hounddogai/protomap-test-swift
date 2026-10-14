@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionAdjustmentTests {
    @Test func startsInRequested() throws {
        let item = Labs.newLegacyAccessionAdjustment("code-907", name: "name-252")
        #expect(item.status == Labs.LegacyAccessionAdjustmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newLegacyAccessionAdjustment("code-907", name: "name-252")
        try item.moveTo(Labs.LegacyAccessionAdjustmentStatus.granted)
        #expect(item.status == Labs.LegacyAccessionAdjustmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newLegacyAccessionAdjustment("code-907", name: "name-252")
        item.status = Labs.LegacyAccessionAdjustmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyAccessionAdjustmentStatus.requested) }
    }
}
