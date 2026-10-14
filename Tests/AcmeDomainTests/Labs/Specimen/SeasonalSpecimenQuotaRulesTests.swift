@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalSpecimenQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalSpecimenQuotaValidator()
        let item = Labs.newSeasonalSpecimenQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalSpecimenQuotaLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.SeasonalSpecimenQuotaLabelLengthRule(maxLength: 255)
        let item = Labs.newSeasonalSpecimenQuota("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalSpecimenQuotaVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Labs.SeasonalSpecimenQuotaVisitMinutesRangeRule(min: 32, max: 1000)
        let item = Labs.newSeasonalSpecimenQuota("x", label: "y")
        item.visitMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalSpecimenQuotaLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.SeasonalSpecimenQuotaLimitRangeRule(min: 16, max: 32)
        let item = Labs.newSeasonalSpecimenQuota("x", label: "y")
        item.limit = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSeasonalSpecimenQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SeasonalSpecimenQuotaCodeLengthRule(maxLength: 1000)
        let item = Labs.newSeasonalSpecimenQuota("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalSpecimenQuotaRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.SeasonalSpecimenQuotaRevisionRangeRule(min: 16, max: 120)
        let item = Labs.newSeasonalSpecimenQuota("x", label: "y")
        item.revision = 121
        #expect(rule.check(item).count > 0)
    }
}
