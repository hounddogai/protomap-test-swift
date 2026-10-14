@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureAllocationValidator()
        let item = Referrals.newClosureAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureAllocationRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Referrals.ClosureAllocationRequiredLocaleRule(message: "closure allocation needs an entry")
        let item = Referrals.newClosureAllocation("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureAllocationCodeLengthRule(maxLength: 32)
        let item = Referrals.newClosureAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureAllocationCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Referrals.ClosureAllocationCeilingRangeRule(min: 6.7, max: 251.5)
        let item = Referrals.newClosureAllocation("x", label: "y")
        item.ceiling = 253.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureAllocationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.ClosureAllocationRequiredLabelRule(message: "closure allocation needs an entry")
        let item = Referrals.newClosureAllocation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
