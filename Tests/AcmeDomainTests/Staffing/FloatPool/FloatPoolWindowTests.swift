@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolWindowTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newFloatPoolWindow("code-823", label: "label-929")
        #expect(item.status == Staffing.FloatPoolWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Staffing.newFloatPoolWindow("code-823", label: "label-929")
        try item.moveTo(Staffing.FloatPoolWindowStatus.archived)
        #expect(item.status == Staffing.FloatPoolWindowStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newFloatPoolWindow("code-823", label: "label-929")
        item.status = Staffing.FloatPoolWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolWindowStatus.`open`) }
    }
}
