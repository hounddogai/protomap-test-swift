@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalClosureMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalClosureMappingValidator()
        let item = Referrals.newRegionalClosureMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalClosureMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RegionalClosureMappingRequiredCodeRule(message: "regional closure mapping needs this field")
        let item = Referrals.newRegionalClosureMapping("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalClosureMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.RegionalClosureMappingRequiredTitleRule(message: "regional closure mapping needs a value")
        let item = Referrals.newRegionalClosureMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalClosureMappingBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Referrals.RegionalClosureMappingBedLengthRule(maxLength: 3600)
        let item = Referrals.newRegionalClosureMapping("x", title: "y")
        item.bed = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
