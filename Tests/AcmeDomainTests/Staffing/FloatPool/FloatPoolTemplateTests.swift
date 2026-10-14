@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolTemplateTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newFloatPoolTemplate("code-988", name: "name-627")
        #expect(item.status == Staffing.FloatPoolTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newFloatPoolTemplate("code-988", name: "name-627")
        try item.moveTo(Staffing.FloatPoolTemplateStatus.rejected)
        #expect(item.status == Staffing.FloatPoolTemplateStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newFloatPoolTemplate("code-988", name: "name-627")
        item.status = Staffing.FloatPoolTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolTemplateStatus.proposed) }
    }
}
