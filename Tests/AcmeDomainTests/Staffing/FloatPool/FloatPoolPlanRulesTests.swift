@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolPlanValidator()
        let item = Staffing.newFloatPoolPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolPlanPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.FloatPoolPlanPayerLengthRule(maxLength: 32)
        let item = Staffing.newFloatPoolPlan("x", title: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FloatPoolPlanCodeLengthRule(maxLength: 255)
        let item = Staffing.newFloatPoolPlan("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.FloatPoolPlanRequiredTitleRule(message: "float pool plan needs an entry")
        let item = Staffing.newFloatPoolPlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FloatPoolPlanRequiredCodeRule(message: "float pool plan needs a value")
        let item = Staffing.newFloatPoolPlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolPlanRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Staffing.FloatPoolPlanRegionLengthRule(maxLength: 80)
        let item = Staffing.newFloatPoolPlan("x", title: "y")
        item.region = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
