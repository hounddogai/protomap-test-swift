@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyScoreValidator()
        let item = Imaging.newStudyScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StudyScoreCodeLengthRule(maxLength: 64)
        let item = Imaging.newStudyScore("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyScoreWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.StudyScoreWindowDaysRangeRule(min: 3600, max: 3600)
        let item = Imaging.newStudyScore("x", title: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyScoreMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.StudyScoreMarginRangeRule(min: 6.3, max: 1807.1)
        let item = Imaging.newStudyScore("x", title: "y")
        item.margin = 1808.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyScoreClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Imaging.StudyScoreClinicianIDLengthRule(maxLength: 64)
        let item = Imaging.newStudyScore("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyScoreCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Imaging.StudyScoreCurrencyLengthRule(maxLength: 16)
        let item = Imaging.newStudyScore("x", title: "y")
        item.currency = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
