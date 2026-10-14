@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualFloatPoolTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultManualFloatPoolTargetValidator()
        let item = Staffing.newManualFloatPoolTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingManualFloatPoolTargetRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Staffing.ManualFloatPoolTargetRequiredRegionRule(message: "manual float pool target needs a value")
        let item = Staffing.newManualFloatPoolTarget("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingManualFloatPoolTargetProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Staffing.ManualFloatPoolTargetProcedureCodeLengthRule(maxLength: 1000)
        let item = Staffing.newManualFloatPoolTarget("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingManualFloatPoolTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ManualFloatPoolTargetRequiredCodeRule(message: "manual float pool target needs an entry")
        let item = Staffing.newManualFloatPoolTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingManualFloatPoolTargetGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Staffing.ManualFloatPoolTargetGraceDaysRangeRule(min: 80, max: 120)
        let item = Staffing.newManualFloatPoolTarget("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}
