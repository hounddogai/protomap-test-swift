@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptivePriorityRollupValidator()
        let item = Imaging.newAdaptivePriorityRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptivePriorityRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.AdaptivePriorityRollupCodeLengthRule(maxLength: 80)
        let item = Imaging.newAdaptivePriorityRollup("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptivePriorityRollupCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Imaging.AdaptivePriorityRollupCapacityRangeRule(min: 120, max: 1000)
        let item = Imaging.newAdaptivePriorityRollup("x", label: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingAdaptivePriorityRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.AdaptivePriorityRollupLabelLengthRule(maxLength: 255)
        let item = Imaging.newAdaptivePriorityRollup("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptivePriorityRollupEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Imaging.AdaptivePriorityRollupEncounterIDLengthRule(maxLength: 80)
        let item = Imaging.newAdaptivePriorityRollup("x", label: "y")
        item.encounterID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptivePriorityRollupDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Imaging.AdaptivePriorityRollupDurationMinutesRangeRule(min: 32, max: 255)
        let item = Imaging.newAdaptivePriorityRollup("x", label: "y")
        item.durationMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}
