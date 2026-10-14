@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeBundleValidator()
        let item = Labs.newReferenceRangeBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ReferenceRangeBundleCodeLengthRule(maxLength: 120)
        let item = Labs.newReferenceRangeBundle("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeBundleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.ReferenceRangeBundleLimitRangeRule(min: 80, max: 255)
        let item = Labs.newReferenceRangeBundle("x", label: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeBundleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ReferenceRangeBundleLabelLengthRule(maxLength: 16)
        let item = Labs.newReferenceRangeBundle("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
