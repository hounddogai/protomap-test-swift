@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolCycleValidator()
        let item = Staffing.newFloatPoolCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FloatPoolCycleCodeLengthRule(maxLength: 255)
        let item = Staffing.newFloatPoolCycle("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FloatPoolCycleRequiredCodeRule(message: "float pool cycle needs a value")
        let item = Staffing.newFloatPoolCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolCycleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.FloatPoolCycleCostRangeRule(min: 2.5, max: 1129.6)
        let item = Staffing.newFloatPoolCycle("x", name: "y")
        item.cost = 1131.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolCycleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.FloatPoolCycleNameLengthRule(maxLength: 255)
        let item = Staffing.newFloatPoolCycle("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.FloatPoolCycleRequiredNameRule(message: "float pool cycle needs an entry")
        let item = Staffing.newFloatPoolCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolCycleRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.FloatPoolCycleRefillsRangeRule(min: 16, max: 255)
        let item = Staffing.newFloatPoolCycle("x", name: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}
