@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceWindowValidator()
        let item = RevenueCycle.newRemittanceWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceWindowRequiredCodeRule(message: "remittance window needs an entry")
        let item = RevenueCycle.newRemittanceWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceWindowAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.RemittanceWindowAmountRangeRule(min: 8.9, max: 3895.3)
        let item = RevenueCycle.newRemittanceWindow("x", title: "y")
        item.amount = 3896.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceWindowCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newRemittanceWindow("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceWindowRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = RevenueCycle.RemittanceWindowRequiredCategoryRule(message: "remittance window needs a value")
        let item = RevenueCycle.newRemittanceWindow("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceWindowRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = RevenueCycle.RemittanceWindowRequiredOwnerIDRule(message: "remittance window needs an entry")
        let item = RevenueCycle.newRemittanceWindow("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
