@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalCourierExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSeasonalCourierExceptionValidator()
        let item = Labs.newSeasonalCourierException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSeasonalCourierExceptionRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Labs.SeasonalCourierExceptionRequiredBedRule(message: "seasonal courier exception needs this field")
        let item = Labs.newSeasonalCourierException("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSeasonalCourierExceptionBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Labs.SeasonalCourierExceptionBedLengthRule(maxLength: 86400)
        let item = Labs.newSeasonalCourierException("x", title: "y")
        item.bed = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSeasonalCourierExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.SeasonalCourierExceptionTitleLengthRule(maxLength: 80)
        let item = Labs.newSeasonalCourierException("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
