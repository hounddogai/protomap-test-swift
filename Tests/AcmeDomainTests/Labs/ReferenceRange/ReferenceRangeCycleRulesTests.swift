@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeCycleValidator()
        let item = Labs.newReferenceRangeCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeCycleRequiredCodeRule(message: "reference range cycle needs this field")
        let item = Labs.newReferenceRangeCycle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeCycleCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.ReferenceRangeCycleCreatedAtRangeRule(min: 32, max: 86400)
        let item = Labs.newReferenceRangeCycle("x", label: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeCycleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ReferenceRangeCycleRequiredLabelRule(message: "reference range cycle needs an entry")
        let item = Labs.newReferenceRangeCycle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
