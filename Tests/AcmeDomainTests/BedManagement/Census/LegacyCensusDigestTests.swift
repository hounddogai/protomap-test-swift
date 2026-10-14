@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusDigestTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newLegacyCensusDigest("code-45", label: "label-201")
        #expect(item.status == BedManagement.LegacyCensusDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newLegacyCensusDigest("code-45", label: "label-201")
        try item.moveTo(BedManagement.LegacyCensusDigestStatus.published)
        #expect(item.status == BedManagement.LegacyCensusDigestStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newLegacyCensusDigest("code-45", label: "label-201")
        item.status = BedManagement.LegacyCensusDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyCensusDigestStatus.created) }
    }
}
