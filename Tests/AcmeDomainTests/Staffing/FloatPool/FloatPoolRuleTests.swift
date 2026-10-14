@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolRuleTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newFloatPoolRule("code-788", title: "title-620")
        #expect(item.status == Staffing.FloatPoolRuleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newFloatPoolRule("code-788", title: "title-620")
        try item.moveTo(Staffing.FloatPoolRuleStatus.published)
        #expect(item.status == Staffing.FloatPoolRuleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newFloatPoolRule("code-788", title: "title-620")
        item.status = Staffing.FloatPoolRuleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolRuleStatus.created) }
    }
}
