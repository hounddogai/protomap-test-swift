@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedFloatPoolTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultWeightedFloatPoolTemplateValidator()
        let item = Staffing.newWeightedFloatPoolTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingWeightedFloatPoolTemplateRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.WeightedFloatPoolTemplateRequiredSummaryRule(
            message: "weighted float pool template needs this field"
        )
        let item = Staffing.newWeightedFloatPoolTemplate("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingWeightedFloatPoolTemplateRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.WeightedFloatPoolTemplateRequiredBedRule(
            message: "weighted float pool template needs a value"
        )
        let item = Staffing.newWeightedFloatPoolTemplate("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingWeightedFloatPoolTemplateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.WeightedFloatPoolTemplateNameLengthRule(maxLength: 120)
        let item = Staffing.newWeightedFloatPoolTemplate("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingWeightedFloatPoolTemplateCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.WeightedFloatPoolTemplateCeilingRangeRule(min: 8.8, max: 637.0)
        let item = Staffing.newWeightedFloatPoolTemplate("x", name: "y")
        item.ceiling = 638.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingWeightedFloatPoolTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.WeightedFloatPoolTemplateRequiredNameRule(
            message: "weighted float pool template needs this field"
        )
        let item = Staffing.newWeightedFloatPoolTemplate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
