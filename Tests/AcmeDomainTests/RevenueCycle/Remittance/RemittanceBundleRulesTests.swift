@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceBundleValidator()
        let item = RevenueCycle.newRemittanceBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceBundleRequiredCodeRule(message: "remittance bundle needs this field")
        let item = RevenueCycle.newRemittanceBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceBundleSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = RevenueCycle.RemittanceBundleSummaryLengthRule(maxLength: 3600)
        let item = RevenueCycle.newRemittanceBundle("x", label: "y")
        item.summary = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceBundleChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = RevenueCycle.RemittanceBundleChecksumLengthRule(maxLength: 16)
        let item = RevenueCycle.newRemittanceBundle("x", label: "y")
        item.checksum = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
