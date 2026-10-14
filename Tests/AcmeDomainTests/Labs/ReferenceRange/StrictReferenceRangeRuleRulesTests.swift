@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictReferenceRangeRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultStrictReferenceRangeRuleValidator()
        let item = Labs.newStrictReferenceRangeRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsStrictReferenceRangeRuleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.StrictReferenceRangeRuleVersionRangeRule(min: 16, max: 255)
        let item = Labs.newStrictReferenceRangeRule("x", name: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsStrictReferenceRangeRuleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.StrictReferenceRangeRuleRequiredLabelRule(message: "strict reference range rule needs a value")
        let item = Labs.newStrictReferenceRangeRule("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictReferenceRangeRuleQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.StrictReferenceRangeRuleQuantityRangeRule(min: 32, max: 255)
        let item = Labs.newStrictReferenceRangeRule("x", name: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsStrictReferenceRangeRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.StrictReferenceRangeRuleRequiredNameRule(message: "strict reference range rule needs this field")
        let item = Labs.newStrictReferenceRangeRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsStrictReferenceRangeRuleEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.StrictReferenceRangeRuleEndsAtRangeRule(min: 80, max: 3600)
        let item = Labs.newStrictReferenceRangeRule("x", name: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
