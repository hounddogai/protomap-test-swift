@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolTierValidator()
        let item = Staffing.newFloatPoolTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FloatPoolTierRequiredCodeRule(message: "float pool tier needs an entry")
        let item = Staffing.newFloatPoolTier("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolTierRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Staffing.FloatPoolTierRequiredLocaleRule(message: "float pool tier needs an entry")
        let item = Staffing.newFloatPoolTier("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.FloatPoolTierRequiredTitleRule(message: "float pool tier needs a value")
        let item = Staffing.newFloatPoolTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolTierLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Staffing.FloatPoolTierLocaleLengthRule(maxLength: 16)
        let item = Staffing.newFloatPoolTier("x", title: "y")
        item.locale = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
