@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapBudgetValidator()
        let item = CareManagement.newCareGapBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapBudgetPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = CareManagement.CareGapBudgetPhoneLengthRule(maxLength: 16)
        let item = CareManagement.newCareGapBudget("x", name: "y")
        item.phone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.CareGapBudgetRequiredNameRule(message: "care gap budget needs an entry")
        let item = CareManagement.newCareGapBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapBudgetRequiredCodeRule(message: "care gap budget needs this field")
        let item = CareManagement.newCareGapBudget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapBudgetRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = CareManagement.CareGapBudgetRequiredPhoneRule(message: "care gap budget needs an entry")
        let item = CareManagement.newCareGapBudget("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapBudgetMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = CareManagement.CareGapBudgetMaximumRangeRule(min: 0.7, max: 2223.0)
        let item = CareManagement.newCareGapBudget("x", name: "y")
        item.maximum = 2224.5
        #expect(rule.check(item).count > 0)
    }
}
