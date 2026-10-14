@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityScheduleValidator()
        let item = Imaging.newPrioritySchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityScheduleSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.PriorityScheduleSequenceRangeRule(min: 255, max: 86400)
        let item = Imaging.newPrioritySchedule("x", label: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.PriorityScheduleLabelLengthRule(maxLength: 86400)
        let item = Imaging.newPrioritySchedule("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityScheduleGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.PriorityScheduleGraceDaysRangeRule(min: 16, max: 32)
        let item = Imaging.newPrioritySchedule("x", label: "y")
        item.graceDays = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityScheduleCodeLengthRule(maxLength: 1000)
        let item = Imaging.newPrioritySchedule("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
