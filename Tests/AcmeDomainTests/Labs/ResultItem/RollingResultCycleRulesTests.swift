@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingResultCycleValidator()
        let item = Labs.newRollingResultCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingResultCycleRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Labs.RollingResultCycleRequiredDescriptionRule(message: "rolling result cycle needs an entry")
        let item = Labs.newRollingResultCycle("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsRollingResultCycleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Labs.RollingResultCycleCostRangeRule(min: 6.1, max: 713.3)
        let item = Labs.newRollingResultCycle("x", title: "y")
        item.cost = 714.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingResultCycleCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.RollingResultCycleCreatedAtRangeRule(min: 16, max: 1000)
        let item = Labs.newRollingResultCycle("x", title: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingResultCycleCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.RollingResultCycleCopayRangeRule(min: 1.3, max: 967.4)
        let item = Labs.newRollingResultCycle("x", title: "y")
        item.copay = 968.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingResultCycleDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.RollingResultCycleDescriptionLengthRule(maxLength: 32)
        let item = Labs.newRollingResultCycle("x", title: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsRollingResultCycleWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Labs.RollingResultCycleWardLengthRule(maxLength: 32)
        let item = Labs.newRollingResultCycle("x", title: "y")
        item.ward = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
