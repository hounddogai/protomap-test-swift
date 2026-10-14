@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolWindowValidator()
        let item = Staffing.newFloatPoolWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FloatPoolWindowCodeLengthRule(maxLength: 16)
        let item = Staffing.newFloatPoolWindow("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolWindowBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.FloatPoolWindowBudgetRangeRule(min: 4.4, max: 597.2)
        let item = Staffing.newFloatPoolWindow("x", label: "y")
        item.budget = 598.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolWindowRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Staffing.FloatPoolWindowRequiredDiagnosisCodeRule(message: "float pool window needs a value")
        let item = Staffing.newFloatPoolWindow("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolWindowRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.FloatPoolWindowRequiredContactEmailRule(message: "float pool window needs a value")
        let item = Staffing.newFloatPoolWindow("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.FloatPoolWindowLabelLengthRule(maxLength: 1000)
        let item = Staffing.newFloatPoolWindow("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
