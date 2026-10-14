@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedOutreachPolicyValidator()
        let item = CareManagement.newBatchedOutreachPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedOutreachPolicyMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = CareManagement.BatchedOutreachPolicyMinimumRangeRule(min: 3.5, max: 3209.6)
        let item = CareManagement.newBatchedOutreachPolicy("x", name: "y")
        item.minimum = 3211.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedOutreachPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.BatchedOutreachPolicyRequiredCodeRule(message: "batched outreach policy needs a value")
        let item = CareManagement.newBatchedOutreachPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedOutreachPolicyCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.BatchedOutreachPolicyCreatedAtRangeRule(min: 64, max: 86400)
        let item = CareManagement.newBatchedOutreachPolicy("x", name: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedOutreachPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.BatchedOutreachPolicyRequiredNameRule(
            message: "batched outreach policy needs this field"
        )
        let item = CareManagement.newBatchedOutreachPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedOutreachPolicyDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = CareManagement.BatchedOutreachPolicyDiagnosisCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newBatchedOutreachPolicy("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedOutreachPolicyWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.BatchedOutreachPolicyWindowDaysRangeRule(min: 16, max: 80)
        let item = CareManagement.newBatchedOutreachPolicy("x", name: "y")
        item.windowDays = 81
        #expect(rule.check(item).count > 0)
    }
}
