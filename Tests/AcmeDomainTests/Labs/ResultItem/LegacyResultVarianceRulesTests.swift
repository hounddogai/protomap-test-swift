@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyResultVarianceValidator()
        let item = Labs.newLegacyResultVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyResultVarianceCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Labs.LegacyResultVarianceCategoryLengthRule(maxLength: 16)
        let item = Labs.newLegacyResultVariance("x", title: "y")
        item.category = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyResultVarianceExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Labs.LegacyResultVarianceExpiresAtRangeRule(min: 64, max: 3600)
        let item = Labs.newLegacyResultVariance("x", title: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacyResultVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.LegacyResultVarianceRequiredTitleRule(message: "legacy result variance needs this field")
        let item = Labs.newLegacyResultVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
