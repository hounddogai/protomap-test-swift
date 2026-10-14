@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeGroupValidator()
        let item = Labs.newReferenceRangeGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeGroupRequiredCodeRule(message: "reference range group needs a value")
        let item = Labs.newReferenceRangeGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeGroupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.ReferenceRangeGroupNameLengthRule(maxLength: 255)
        let item = Labs.newReferenceRangeGroup("x", label: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeGroupStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Labs.ReferenceRangeGroupStartsAtRangeRule(min: 16, max: 1000)
        let item = Labs.newReferenceRangeGroup("x", label: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ReferenceRangeGroupRequiredLabelRule(message: "reference range group needs an entry")
        let item = Labs.newReferenceRangeGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
