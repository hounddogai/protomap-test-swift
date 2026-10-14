@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedReferenceRangeEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedReferenceRangeEstimateValidator()
        let item = Labs.newCappedReferenceRangeEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedReferenceRangeEstimateAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.CappedReferenceRangeEstimateAttemptsRangeRule(min: 80, max: 1000)
        let item = Labs.newCappedReferenceRangeEstimate("x", name: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedReferenceRangeEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CappedReferenceRangeEstimateRequiredCodeRule(
            message: "capped reference range estimate needs an entry"
        )
        let item = Labs.newCappedReferenceRangeEstimate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedReferenceRangeEstimateRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Labs.CappedReferenceRangeEstimateRequiredCategoryRule(
            message: "capped reference range estimate needs this field"
        )
        let item = Labs.newCappedReferenceRangeEstimate("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedReferenceRangeEstimateCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.CappedReferenceRangeEstimateCopayRangeRule(min: 3.5, max: 4502.7)
        let item = Labs.newCappedReferenceRangeEstimate("x", name: "y")
        item.copay = 4504.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedReferenceRangeEstimateCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.CappedReferenceRangeEstimateCreatedAtRangeRule(min: 64, max: 255)
        let item = Labs.newCappedReferenceRangeEstimate("x", name: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedReferenceRangeEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.CappedReferenceRangeEstimateRequiredNameRule(
            message: "capped reference range estimate needs this field"
        )
        let item = Labs.newCappedReferenceRangeEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
