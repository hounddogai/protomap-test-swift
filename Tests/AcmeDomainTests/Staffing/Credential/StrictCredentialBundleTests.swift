@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictCredentialBundleTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newStrictCredentialBundle("code-304", name: "name-670")
        #expect(item.status == Staffing.StrictCredentialBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newStrictCredentialBundle("code-304", name: "name-670")
        try item.moveTo(Staffing.StrictCredentialBundleStatus.resolved)
        #expect(item.status == Staffing.StrictCredentialBundleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newStrictCredentialBundle("code-304", name: "name-670")
        item.status = Staffing.StrictCredentialBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictCredentialBundleStatus.`open`) }
    }
}
