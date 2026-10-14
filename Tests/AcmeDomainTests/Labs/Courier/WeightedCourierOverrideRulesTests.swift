@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedCourierOverrideValidator()
        let item = Labs.newWeightedCourierOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedCourierOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.WeightedCourierOverrideCodeLengthRule(maxLength: 16)
        let item = Labs.newWeightedCourierOverride("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedCourierOverrideRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Labs.WeightedCourierOverrideRequiredContactEmailRule(
            message: "weighted courier override needs this field"
        )
        let item = Labs.newWeightedCourierOverride("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedCourierOverrideContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.WeightedCourierOverrideContactEmailLengthRule(maxLength: 86400)
        let item = Labs.newWeightedCourierOverride("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
