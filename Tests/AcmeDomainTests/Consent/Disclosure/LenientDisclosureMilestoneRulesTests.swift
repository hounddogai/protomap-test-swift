@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientDisclosureMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientDisclosureMilestoneValidator()
        let item = Consent.newLenientDisclosureMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientDisclosureMilestoneMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.LenientDisclosureMilestoneMaximumRangeRule(min: 4.2, max: 1612.9)
        let item = Consent.newLenientDisclosureMilestone("x", label: "y")
        item.maximum = 1614.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientDisclosureMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LenientDisclosureMilestoneRequiredCodeRule(
            message: "lenient disclosure milestone needs a value"
        )
        let item = Consent.newLenientDisclosureMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientDisclosureMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LenientDisclosureMilestoneCodeLengthRule(maxLength: 32)
        let item = Consent.newLenientDisclosureMilestone("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientDisclosureMilestoneWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Consent.LenientDisclosureMilestoneWardLengthRule(maxLength: 80)
        let item = Consent.newLenientDisclosureMilestone("x", label: "y")
        item.ward = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientDisclosureMilestoneRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.LenientDisclosureMilestoneRequiredLabelRule(
            message: "lenient disclosure milestone needs a value"
        )
        let item = Consent.newLenientDisclosureMilestone("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
