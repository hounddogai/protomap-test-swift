@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackOvertimePolicyTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newFallbackOvertimePolicy("code-825", name: "name-420")
        #expect(item.status == Staffing.FallbackOvertimePolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newFallbackOvertimePolicy("code-825", name: "name-420")
        try item.moveTo(Staffing.FallbackOvertimePolicyStatus.resolved)
        #expect(item.status == Staffing.FallbackOvertimePolicyStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newFallbackOvertimePolicy("code-825", name: "name-420")
        item.status = Staffing.FallbackOvertimePolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackOvertimePolicyStatus.`open`) }
    }
}
