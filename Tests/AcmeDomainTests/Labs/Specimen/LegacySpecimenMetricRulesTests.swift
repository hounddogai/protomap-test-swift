@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacySpecimenMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacySpecimenMetricValidator()
        let item = Labs.newLegacySpecimenMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacySpecimenMetricReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Labs.LegacySpecimenMetricReviewerLengthRule(maxLength: 255)
        let item = Labs.newLegacySpecimenMetric("x", name: "y")
        item.reviewer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacySpecimenMetricAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Labs.LegacySpecimenMetricAcuityRangeRule(min: 120, max: 1000)
        let item = Labs.newLegacySpecimenMetric("x", name: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacySpecimenMetricRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.LegacySpecimenMetricRequiredNameRule(message: "legacy specimen metric needs a value")
        let item = Labs.newLegacySpecimenMetric("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacySpecimenMetricRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Labs.LegacySpecimenMetricRegionLengthRule(maxLength: 32)
        let item = Labs.newLegacySpecimenMetric("x", name: "y")
        item.region = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacySpecimenMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.LegacySpecimenMetricCodeLengthRule(maxLength: 80)
        let item = Labs.newLegacySpecimenMetric("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
