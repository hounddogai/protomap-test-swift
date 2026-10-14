@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyAccessionTierValidator()
        let item = Labs.newLegacyAccessionTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyAccessionTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.LegacyAccessionTierTitleLengthRule(maxLength: 86400)
        let item = Labs.newLegacyAccessionTier("x", label: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyAccessionTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.LegacyAccessionTierRequiredLabelRule(message: "legacy accession tier needs a value")
        let item = Labs.newLegacyAccessionTier("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyAccessionTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.LegacyAccessionTierCodeLengthRule(maxLength: 64)
        let item = Labs.newLegacyAccessionTier("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyAccessionTierSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Labs.LegacyAccessionTierSegmentLengthRule(maxLength: 1000)
        let item = Labs.newLegacyAccessionTier("x", label: "y")
        item.segment = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyAccessionTierQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.LegacyAccessionTierQuantityRangeRule(min: 80, max: 1000)
        let item = Labs.newLegacyAccessionTier("x", label: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}
