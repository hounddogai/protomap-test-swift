@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictFloatPoolManifestTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newStrictFloatPoolManifest("code-264", name: "name-390")
        #expect(item.status == Staffing.StrictFloatPoolManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newStrictFloatPoolManifest("code-264", name: "name-390")
        try item.moveTo(Staffing.StrictFloatPoolManifestStatus.resolved)
        #expect(item.status == Staffing.StrictFloatPoolManifestStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newStrictFloatPoolManifest("code-264", name: "name-390")
        item.status = Staffing.StrictFloatPoolManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictFloatPoolManifestStatus.`open`) }
    }
}
