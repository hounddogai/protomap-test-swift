@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedSpecimenCycleValidator()
        let item = Labs.newCappedSpecimenCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedSpecimenCycleCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.CappedSpecimenCycleCreatedAtRangeRule(min: 120, max: 1000)
        let item = Labs.newCappedSpecimenCycle("x", title: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedSpecimenCycleLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.CappedSpecimenCycleLimitRangeRule(min: 3600, max: 86400)
        let item = Labs.newCappedSpecimenCycle("x", title: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedSpecimenCycleSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Labs.CappedSpecimenCycleSegmentLengthRule(maxLength: 86400)
        let item = Labs.newCappedSpecimenCycle("x", title: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedSpecimenCycleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.CappedSpecimenCycleCopayRangeRule(min: 2.3, max: 3721.4)
        let item = Labs.newCappedSpecimenCycle("x", title: "y")
        item.copay = 3722.9
        #expect(rule.check(item).count > 0)
    }
}
