@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalOutreachDigestTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newSeasonalOutreachDigest("code-404", name: "name-206")
        #expect(item.status == CareManagement.SeasonalOutreachDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newSeasonalOutreachDigest("code-404", name: "name-206")
        try item.moveTo(CareManagement.SeasonalOutreachDigestStatus.done)
        #expect(item.status == CareManagement.SeasonalOutreachDigestStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newSeasonalOutreachDigest("code-404", name: "name-206")
        item.status = CareManagement.SeasonalOutreachDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalOutreachDigestStatus.new) }
    }
}
