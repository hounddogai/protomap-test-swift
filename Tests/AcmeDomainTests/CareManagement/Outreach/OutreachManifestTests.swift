@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachManifestTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newOutreachManifest("code-474", name: "name-81")
        #expect(item.status == CareManagement.OutreachManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = CareManagement.newOutreachManifest("code-474", name: "name-81")
        try item.moveTo(CareManagement.OutreachManifestStatus.retired)
        #expect(item.status == CareManagement.OutreachManifestStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newOutreachManifest("code-474", name: "name-81")
        item.status = CareManagement.OutreachManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachManifestStatus.created) }
    }
}
