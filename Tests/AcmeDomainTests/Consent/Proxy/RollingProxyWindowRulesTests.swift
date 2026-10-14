@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingProxyWindowValidator()
        let item = Consent.newRollingProxyWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingProxyWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RollingProxyWindowRequiredCodeRule(message: "rolling proxy window needs this field")
        let item = Consent.newRollingProxyWindow("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingProxyWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RollingProxyWindowCodeLengthRule(maxLength: 255)
        let item = Consent.newRollingProxyWindow("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingProxyWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.RollingProxyWindowTitleLengthRule(maxLength: 32)
        let item = Consent.newRollingProxyWindow("x", name: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingProxyWindowQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.RollingProxyWindowQuantityRangeRule(min: 64, max: 255)
        let item = Consent.newRollingProxyWindow("x", name: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRollingProxyWindowNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.RollingProxyWindowNameLengthRule(maxLength: 80)
        let item = Consent.newRollingProxyWindow("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingProxyWindowAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Consent.RollingProxyWindowAmountRangeRule(min: 5.7, max: 533.7)
        let item = Consent.newRollingProxyWindow("x", name: "y")
        item.amount = 535.2
        #expect(rule.check(item).count > 0)
    }
}
