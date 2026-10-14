@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryFloatPoolManifestTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newPrimaryFloatPoolManifest("code-425", label: "label-401")
        #expect(item.status == Staffing.PrimaryFloatPoolManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newPrimaryFloatPoolManifest("code-425", label: "label-401")
        try item.moveTo(Staffing.PrimaryFloatPoolManifestStatus.validated)
        #expect(item.status == Staffing.PrimaryFloatPoolManifestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newPrimaryFloatPoolManifest("code-425", label: "label-401")
        item.status = Staffing.PrimaryFloatPoolManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryFloatPoolManifestStatus.created) }
    }
}
