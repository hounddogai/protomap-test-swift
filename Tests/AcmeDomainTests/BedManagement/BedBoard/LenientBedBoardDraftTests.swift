@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientBedBoardDraftTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newLenientBedBoardDraft("code-692", label: "label-263")
        #expect(item.status == BedManagement.LenientBedBoardDraftStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newLenientBedBoardDraft("code-692", label: "label-263")
        try item.moveTo(BedManagement.LenientBedBoardDraftStatus.warming)
        #expect(item.status == BedManagement.LenientBedBoardDraftStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newLenientBedBoardDraft("code-692", label: "label-263")
        item.status = BedManagement.LenientBedBoardDraftStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientBedBoardDraftStatus.idle) }
    }
}
