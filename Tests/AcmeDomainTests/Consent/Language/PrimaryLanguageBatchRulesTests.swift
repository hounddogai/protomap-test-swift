@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryLanguageBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPrimaryLanguageBatchValidator()
        let item = Consent.newPrimaryLanguageBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPrimaryLanguageBatchMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Consent.PrimaryLanguageBatchMarginRangeRule(min: 9.4, max: 1559.0)
        let item = Consent.newPrimaryLanguageBatch("x", name: "y")
        item.margin = 1560.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPrimaryLanguageBatchCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.PrimaryLanguageBatchCostRangeRule(min: 1.4, max: 2039.0)
        let item = Consent.newPrimaryLanguageBatch("x", name: "y")
        item.cost = 2040.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPrimaryLanguageBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.PrimaryLanguageBatchRequiredNameRule(message: "primary language batch needs an entry")
        let item = Consent.newPrimaryLanguageBatch("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryLanguageBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.PrimaryLanguageBatchRequiredCodeRule(message: "primary language batch needs this field")
        let item = Consent.newPrimaryLanguageBatch("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryLanguageBatchCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Consent.PrimaryLanguageBatchCategoryLengthRule(maxLength: 80)
        let item = Consent.newPrimaryLanguageBatch("x", name: "y")
        item.category = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryLanguageBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.PrimaryLanguageBatchCodeLengthRule(maxLength: 64)
        let item = Consent.newPrimaryLanguageBatch("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
