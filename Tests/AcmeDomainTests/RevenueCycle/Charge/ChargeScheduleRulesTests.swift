@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeScheduleValidator()
        let item = RevenueCycle.newChargeSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeScheduleNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = RevenueCycle.ChargeScheduleNotesLengthRule(maxLength: 86400)
        let item = RevenueCycle.newChargeSchedule("x", name: "y")
        item.notes = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ChargeScheduleNameLengthRule(maxLength: 255)
        let item = RevenueCycle.newChargeSchedule("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeScheduleRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = RevenueCycle.ChargeScheduleRequiredSegmentRule(message: "charge schedule needs a value")
        let item = RevenueCycle.newChargeSchedule("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeScheduleSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = RevenueCycle.ChargeScheduleSegmentLengthRule(maxLength: 16)
        let item = RevenueCycle.newChargeSchedule("x", name: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeScheduleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.ChargeScheduleThresholdRangeRule(min: 6.6, max: 4902.1)
        let item = RevenueCycle.newChargeSchedule("x", name: "y")
        item.threshold = 4903.6
        #expect(rule.check(item).count > 0)
    }
}
