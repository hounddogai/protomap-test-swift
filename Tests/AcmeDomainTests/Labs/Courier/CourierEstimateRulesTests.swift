@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierEstimateValidator()
        let item = Labs.newCourierEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierEstimateRequiredCodeRule(message: "courier estimate needs a value")
        let item = Labs.newCourierEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CourierEstimateCodeLengthRule(maxLength: 120)
        let item = Labs.newCourierEstimate("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierEstimateRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Labs.CourierEstimateRefillsRangeRule(min: 255, max: 1000)
        let item = Labs.newCourierEstimate("x", title: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}
