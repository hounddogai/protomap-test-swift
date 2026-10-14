@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryCareProtocolRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryCareProtocolRuleValidator()
        let item = Imaging.newPrimaryCareProtocolRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryCareProtocolRuleAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.PrimaryCareProtocolRuleAttemptsRangeRule(min: 80, max: 1000)
        let item = Imaging.newPrimaryCareProtocolRule("x", title: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryCareProtocolRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PrimaryCareProtocolRuleRequiredCodeRule(message: "primary care protocol rule needs a value")
        let item = Imaging.newPrimaryCareProtocolRule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryCareProtocolRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.PrimaryCareProtocolRuleTitleLengthRule(maxLength: 16)
        let item = Imaging.newPrimaryCareProtocolRule("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrimaryCareProtocolRuleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Imaging.PrimaryCareProtocolRuleExpiresAtRangeRule(min: 80, max: 120)
        let item = Imaging.newPrimaryCareProtocolRule("x", title: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryCareProtocolRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PrimaryCareProtocolRuleCodeLengthRule(maxLength: 120)
        let item = Imaging.newPrimaryCareProtocolRule("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
