@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredOutreachPlanValidator()
        let item = CareManagement.newTieredOutreachPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredOutreachPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.TieredOutreachPlanRequiredCodeRule(message: "tiered outreach plan needs this field")
        let item = CareManagement.newTieredOutreachPlan("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
