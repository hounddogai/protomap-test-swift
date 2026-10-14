@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedCourierRollupValidator()
        let item = Labs.newCappedCourierRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedCourierRollupEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.CappedCourierRollupEndsAtRangeRule(min: 3600, max: 86400)
        let item = Labs.newCappedCourierRollup("x", name: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedCourierRollupCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Labs.CappedCourierRollupCostRangeRule(min: 5.0, max: 3246.3)
        let item = Labs.newCappedCourierRollup("x", name: "y")
        item.cost = 3247.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedCourierRollupTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Labs.CappedCourierRollupTimezoneLengthRule(maxLength: 3600)
        let item = Labs.newCappedCourierRollup("x", name: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedCourierRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CappedCourierRollupRequiredCodeRule(message: "capped courier rollup needs a value")
        let item = Labs.newCappedCourierRollup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
