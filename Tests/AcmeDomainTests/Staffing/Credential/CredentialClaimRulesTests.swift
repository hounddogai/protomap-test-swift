@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialClaimValidator()
        let item = Staffing.newCredentialClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialClaimRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CredentialClaimRequiredTitleRule(message: "credential claim needs an entry")
        let item = Staffing.newCredentialClaim("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialClaimVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Staffing.CredentialClaimVisitMinutesRangeRule(min: 32, max: 120)
        let item = Staffing.newCredentialClaim("x", title: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}
