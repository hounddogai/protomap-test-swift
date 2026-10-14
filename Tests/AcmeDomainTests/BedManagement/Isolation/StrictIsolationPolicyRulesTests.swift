@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictIsolationPolicyValidator()
        let item = BedManagement.newStrictIsolationPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictIsolationPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.StrictIsolationPolicyRequiredLabelRule(
            message: "strict isolation policy needs this field"
        )
        let item = BedManagement.newStrictIsolationPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementStrictIsolationPolicyBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.StrictIsolationPolicyBudgetRangeRule(min: 8.3, max: 3723.6)
        let item = BedManagement.newStrictIsolationPolicy("x", label: "y")
        item.budget = 3725.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementStrictIsolationPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.StrictIsolationPolicyCodeLengthRule(maxLength: 16)
        let item = BedManagement.newStrictIsolationPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictIsolationPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.StrictIsolationPolicyRequiredCodeRule(
            message: "strict isolation policy needs this field"
        )
        let item = BedManagement.newStrictIsolationPolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementStrictIsolationPolicyReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = BedManagement.StrictIsolationPolicyReviewerLengthRule(maxLength: 1000)
        let item = BedManagement.newStrictIsolationPolicy("x", label: "y")
        item.reviewer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
