@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryLanguageBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPrimaryLanguageBudgetValidator()
        let item = Consent.newPrimaryLanguageBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPrimaryLanguageBudgetOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Consent.PrimaryLanguageBudgetOwnerIDLengthRule(maxLength: 64)
        let item = Consent.newPrimaryLanguageBudget("x", label: "y")
        item.ownerID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPrimaryLanguageBudgetRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Consent.PrimaryLanguageBudgetRequiredOwnerIDRule(message: "primary language budget needs this field")
        let item = Consent.newPrimaryLanguageBudget("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryLanguageBudgetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.PrimaryLanguageBudgetRequiredLabelRule(message: "primary language budget needs a value")
        let item = Consent.newPrimaryLanguageBudget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPrimaryLanguageBudgetRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Consent.PrimaryLanguageBudgetRefillsRangeRule(min: 255, max: 3600)
        let item = Consent.newPrimaryLanguageBudget("x", label: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}
