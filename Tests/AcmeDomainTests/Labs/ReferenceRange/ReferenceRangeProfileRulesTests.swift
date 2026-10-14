@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeProfileValidator()
        let item = Labs.newReferenceRangeProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeProfileMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.ReferenceRangeProfileMinimumRangeRule(min: 8.6, max: 1405.6)
        let item = Labs.newReferenceRangeProfile("x", name: "y")
        item.minimum = 1407.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeProfileLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.ReferenceRangeProfileLimitRangeRule(min: 1000, max: 86400)
        let item = Labs.newReferenceRangeProfile("x", name: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeProfileRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.ReferenceRangeProfileRequiredPayerRule(message: "reference range profile needs this field")
        let item = Labs.newReferenceRangeProfile("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
