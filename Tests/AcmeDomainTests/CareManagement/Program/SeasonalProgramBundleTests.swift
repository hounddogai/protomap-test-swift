@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalProgramBundleTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newSeasonalProgramBundle("code-499", title: "title-626")
        #expect(item.status == CareManagement.SeasonalProgramBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newSeasonalProgramBundle("code-499", title: "title-626")
        try item.moveTo(CareManagement.SeasonalProgramBundleStatus.granted)
        #expect(item.status == CareManagement.SeasonalProgramBundleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newSeasonalProgramBundle("code-499", title: "title-626")
        item.status = CareManagement.SeasonalProgramBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalProgramBundleStatus.requested) }
    }
}
