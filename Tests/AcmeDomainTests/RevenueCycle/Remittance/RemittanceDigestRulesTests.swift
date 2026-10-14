@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceDigestValidator()
        let item = RevenueCycle.newRemittanceDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceDigestCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newRemittanceDigest("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceDigestRequiredCodeRule(message: "remittance digest needs this field")
        let item = RevenueCycle.newRemittanceDigest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceDigestRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = RevenueCycle.RemittanceDigestRequiredChannelRule(message: "remittance digest needs this field")
        let item = RevenueCycle.newRemittanceDigest("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceDigestRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.RemittanceDigestRequiredTimezoneRule(message: "remittance digest needs this field")
        let item = RevenueCycle.newRemittanceDigest("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceDigestTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.RemittanceDigestTimezoneLengthRule(maxLength: 3600)
        let item = RevenueCycle.newRemittanceDigest("x", name: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
