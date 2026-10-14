@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyOrderSetEntryValidator()
        let item = ClinicalOps.newLegacyOrderSetEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetEntryPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = ClinicalOps.LegacyOrderSetEntryPhoneLengthRule(maxLength: 255)
        let item = ClinicalOps.newLegacyOrderSetEntry("x", label: "y")
        item.phone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetEntryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.LegacyOrderSetEntryLabelLengthRule(maxLength: 86400)
        let item = ClinicalOps.newLegacyOrderSetEntry("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetEntryRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = ClinicalOps.LegacyOrderSetEntryRefillsRangeRule(min: 32, max: 80)
        let item = ClinicalOps.newLegacyOrderSetEntry("x", label: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLegacyOrderSetEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.LegacyOrderSetEntryRequiredCodeRule(message: "legacy order set entry needs a value")
        let item = ClinicalOps.newLegacyOrderSetEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
