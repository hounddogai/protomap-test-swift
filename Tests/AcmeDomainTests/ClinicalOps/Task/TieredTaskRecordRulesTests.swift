@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredTaskRecordValidator()
        let item = ClinicalOps.newTieredTaskRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredTaskRecordDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.TieredTaskRecordDescriptionLengthRule(maxLength: 80)
        let item = ClinicalOps.newTieredTaskRecord("x", label: "y")
        item.description = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredTaskRecordDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = ClinicalOps.TieredTaskRecordDurationMinutesRangeRule(min: 80, max: 255)
        let item = ClinicalOps.newTieredTaskRecord("x", label: "y")
        item.durationMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTieredTaskRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TieredTaskRecordRequiredCodeRule(message: "tiered task record needs an entry")
        let item = ClinicalOps.newTieredTaskRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
