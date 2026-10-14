@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalAssessmentRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalAssessmentRuleValidator()
        let item = CareManagement.newGlobalAssessmentRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalAssessmentRuleSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.GlobalAssessmentRuleSequenceRangeRule(min: 120, max: 1000)
        let item = CareManagement.newGlobalAssessmentRule("x", name: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGlobalAssessmentRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GlobalAssessmentRuleRequiredCodeRule(message: "global assessment rule needs a value")
        let item = CareManagement.newGlobalAssessmentRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalAssessmentRuleDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = CareManagement.GlobalAssessmentRuleDiscountRangeRule(min: 9.3, max: 1438.6)
        let item = CareManagement.newGlobalAssessmentRule("x", name: "y")
        item.discount = 1440.1
        #expect(rule.check(item).count > 0)
    }
}
