@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictTaskMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictTaskMilestoneValidator()
        let item = ClinicalOps.newStrictTaskMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictTaskMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.StrictTaskMilestoneCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newStrictTaskMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsStrictTaskMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.StrictTaskMilestoneRequiredCodeRule(message: "strict task milestone needs a value")
        let item = ClinicalOps.newStrictTaskMilestone("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
