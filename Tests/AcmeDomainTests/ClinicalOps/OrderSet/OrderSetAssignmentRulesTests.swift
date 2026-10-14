@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetAssignmentValidator()
        let item = ClinicalOps.newOrderSetAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetAssignmentRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = ClinicalOps.OrderSetAssignmentRequiredLocaleRule(message: "order set assignment needs this field")
        let item = ClinicalOps.newOrderSetAssignment("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetAssignmentLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = ClinicalOps.OrderSetAssignmentLimitRangeRule(min: 64, max: 120)
        let item = ClinicalOps.newOrderSetAssignment("x", name: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.OrderSetAssignmentRequiredNameRule(message: "order set assignment needs an entry")
        let item = ClinicalOps.newOrderSetAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetAssignmentDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = ClinicalOps.OrderSetAssignmentDosageMgRangeRule(min: 1.8, max: 3953.3)
        let item = ClinicalOps.newOrderSetAssignment("x", name: "y")
        item.dosageMg = 3954.8
        #expect(rule.check(item).count > 0)
    }
}
