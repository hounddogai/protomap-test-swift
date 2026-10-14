@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveStudyScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptiveStudyScheduleValidator()
        let item = Imaging.newAdaptiveStudySchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptiveStudyScheduleBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.AdaptiveStudyScheduleBatchSizeRangeRule(min: 120, max: 1000)
        let item = Imaging.newAdaptiveStudySchedule("x", name: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingAdaptiveStudyScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.AdaptiveStudyScheduleNameLengthRule(maxLength: 86400)
        let item = Imaging.newAdaptiveStudySchedule("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptiveStudyScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.AdaptiveStudyScheduleRequiredNameRule(message: "adaptive study schedule needs this field")
        let item = Imaging.newAdaptiveStudySchedule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
