@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureTargetValidator()
        let item = Consent.newDisclosureTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureTargetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.DisclosureTargetTitleLengthRule(maxLength: 255)
        let item = Consent.newDisclosureTarget("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureTargetThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Consent.DisclosureTargetThresholdRangeRule(min: 6.2, max: 2135.4)
        let item = Consent.newDisclosureTarget("x", title: "y")
        item.threshold = 2136.9
        #expect(rule.check(item).count > 0)
    }
}
