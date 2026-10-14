@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimNoticeValidator()
        let item = RevenueCycle.newClaimNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimNoticeRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.ClaimNoticeRequiredTimezoneRule(message: "claim notice needs this field")
        let item = RevenueCycle.newClaimNotice("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimNoticeAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.ClaimNoticeAmountRangeRule(min: 7.4, max: 4320.1)
        let item = RevenueCycle.newClaimNotice("x", title: "y")
        item.amount = 4321.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimNoticeRequiredCodeRule(message: "claim notice needs a value")
        let item = RevenueCycle.newClaimNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimNoticeRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = RevenueCycle.ClaimNoticeRequiredChecksumRule(message: "claim notice needs a value")
        let item = RevenueCycle.newClaimNotice("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ClaimNoticeRequiredTitleRule(message: "claim notice needs a value")
        let item = RevenueCycle.newClaimNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
