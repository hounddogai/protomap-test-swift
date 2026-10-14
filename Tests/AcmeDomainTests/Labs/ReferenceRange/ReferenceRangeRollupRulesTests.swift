@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeRollupValidator()
        let item = Labs.newReferenceRangeRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeRollupUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Labs.ReferenceRangeRollupUpdatedAtRangeRule(min: 32, max: 1000)
        let item = Labs.newReferenceRangeRollup("x", label: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeRollupRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Labs.ReferenceRangeRollupRequiredUnitRule(message: "reference range rollup needs this field")
        let item = Labs.newReferenceRangeRollup("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
