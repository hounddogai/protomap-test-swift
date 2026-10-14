@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalOvertimeBundleTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newGlobalOvertimeBundle("code-674", title: "title-113")
        #expect(item.status == Staffing.GlobalOvertimeBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newGlobalOvertimeBundle("code-674", title: "title-113")
        try item.moveTo(Staffing.GlobalOvertimeBundleStatus.resolved)
        #expect(item.status == Staffing.GlobalOvertimeBundleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newGlobalOvertimeBundle("code-674", title: "title-113")
        item.status = Staffing.GlobalOvertimeBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalOvertimeBundleStatus.`open`) }
    }
}
