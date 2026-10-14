@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultOvertimeDigestTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newDefaultOvertimeDigest("code-545", name: "name-374")
        #expect(item.status == Staffing.DefaultOvertimeDigestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newDefaultOvertimeDigest("code-545", name: "name-374")
        try item.moveTo(Staffing.DefaultOvertimeDigestStatus.inReview)
        #expect(item.status == Staffing.DefaultOvertimeDigestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newDefaultOvertimeDigest("code-545", name: "name-374")
        item.status = Staffing.DefaultOvertimeDigestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultOvertimeDigestStatus.`open`) }
    }
}
