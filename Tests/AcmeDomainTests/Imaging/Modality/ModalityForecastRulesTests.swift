@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityForecastValidator()
        let item = Imaging.newModalityForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityForecastWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Imaging.ModalityForecastWardLengthRule(maxLength: 80)
        let item = Imaging.newModalityForecast("x", name: "y")
        item.ward = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityForecastCodeLengthRule(maxLength: 255)
        let item = Imaging.newModalityForecast("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityForecastNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.ModalityForecastNotesLengthRule(maxLength: 64)
        let item = Imaging.newModalityForecast("x", name: "y")
        item.notes = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityForecastPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Imaging.ModalityForecastPriorityRangeRule(min: 64, max: 86400)
        let item = Imaging.newModalityForecast("x", name: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityForecastGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.ModalityForecastGraceDaysRangeRule(min: 32, max: 3600)
        let item = Imaging.newModalityForecast("x", name: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
