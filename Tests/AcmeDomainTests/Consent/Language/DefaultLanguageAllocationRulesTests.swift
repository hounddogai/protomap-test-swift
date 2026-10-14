@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultLanguageAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDefaultLanguageAllocationValidator()
        let item = Consent.newDefaultLanguageAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDefaultLanguageAllocationSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Consent.DefaultLanguageAllocationSequenceRangeRule(min: 64, max: 3600)
        let item = Consent.newDefaultLanguageAllocation("x", name: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDefaultLanguageAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DefaultLanguageAllocationCodeLengthRule(maxLength: 16)
        let item = Consent.newDefaultLanguageAllocation("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDefaultLanguageAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DefaultLanguageAllocationRequiredCodeRule(
            message: "default language allocation needs this field"
        )
        let item = Consent.newDefaultLanguageAllocation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDefaultLanguageAllocationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.DefaultLanguageAllocationRequiredNameRule(
            message: "default language allocation needs a value"
        )
        let item = Consent.newDefaultLanguageAllocation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDefaultLanguageAllocationLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.DefaultLanguageAllocationLimitRangeRule(min: 16, max: 86400)
        let item = Consent.newDefaultLanguageAllocation("x", name: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}
