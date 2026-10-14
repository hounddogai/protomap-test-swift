@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalOutreachManifestTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRegionalOutreachManifest("code-690", title: "title-757")
        #expect(item.status == CareManagement.RegionalOutreachManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newRegionalOutreachManifest("code-690", title: "title-757")
        try item.moveTo(CareManagement.RegionalOutreachManifestStatus.pending)
        #expect(item.status == CareManagement.RegionalOutreachManifestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRegionalOutreachManifest("code-690", title: "title-757")
        item.status = CareManagement.RegionalOutreachManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalOutreachManifestStatus.draft) }
    }
}
