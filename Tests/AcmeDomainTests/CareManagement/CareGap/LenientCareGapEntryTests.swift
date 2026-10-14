@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapEntryTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newLenientCareGapEntry("code-948", title: "title-750")
        #expect(item.status == CareManagement.LenientCareGapEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newLenientCareGapEntry("code-948", title: "title-750")
        try item.moveTo(CareManagement.LenientCareGapEntryStatus.ready)
        #expect(item.status == CareManagement.LenientCareGapEntryStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newLenientCareGapEntry("code-948", title: "title-750")
        item.status = CareManagement.LenientCareGapEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientCareGapEntryStatus.idle) }
    }
}
