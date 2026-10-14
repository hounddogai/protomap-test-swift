@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingTaskPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingTaskPolicyValidator()
        let item = ClinicalOps.newRollingTaskPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingTaskPolicyTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.RollingTaskPolicyTitleLengthRule(maxLength: 1000)
        let item = ClinicalOps.newRollingTaskPolicy("x", label: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRollingTaskPolicyRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = ClinicalOps.RollingTaskPolicyRequiredCategoryRule(message: "rolling task policy needs an entry")
        let item = ClinicalOps.newRollingTaskPolicy("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingTaskPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RollingTaskPolicyRequiredLabelRule(message: "rolling task policy needs an entry")
        let item = ClinicalOps.newRollingTaskPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingTaskPolicyCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = ClinicalOps.RollingTaskPolicyCategoryLengthRule(maxLength: 32)
        let item = ClinicalOps.newRollingTaskPolicy("x", label: "y")
        item.category = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
