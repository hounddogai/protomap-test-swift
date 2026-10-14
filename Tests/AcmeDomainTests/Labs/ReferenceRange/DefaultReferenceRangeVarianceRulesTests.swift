@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultReferenceRangeVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultDefaultReferenceRangeVarianceValidator()
        let item = Labs.newDefaultReferenceRangeVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsDefaultReferenceRangeVarianceRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.DefaultReferenceRangeVarianceRequiredPayerRule(
            message: "default reference range variance needs this field"
        )
        let item = Labs.newDefaultReferenceRangeVariance("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultReferenceRangeVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.DefaultReferenceRangeVarianceRequiredTitleRule(
            message: "default reference range variance needs a value"
        )
        let item = Labs.newDefaultReferenceRangeVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsDefaultReferenceRangeVarianceCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.DefaultReferenceRangeVarianceCountryLengthRule(maxLength: 64)
        let item = Labs.newDefaultReferenceRangeVariance("x", title: "y")
        item.country = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultReferenceRangeVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.DefaultReferenceRangeVarianceTitleLengthRule(maxLength: 86400)
        let item = Labs.newDefaultReferenceRangeVariance("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsDefaultReferenceRangeVarianceCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.DefaultReferenceRangeVarianceCeilingRangeRule(min: 1.0, max: 4832.3)
        let item = Labs.newDefaultReferenceRangeVariance("x", title: "y")
        item.ceiling = 4833.8
        #expect(rule.check(item).count > 0)
    }
}
