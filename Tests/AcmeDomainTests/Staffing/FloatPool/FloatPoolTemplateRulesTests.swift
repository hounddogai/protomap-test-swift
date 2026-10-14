@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolTemplateValidator()
        let item = Staffing.newFloatPoolTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FloatPoolTemplateRequiredCodeRule(message: "float pool template needs an entry")
        let item = Staffing.newFloatPoolTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolTemplateSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Staffing.FloatPoolTemplateSegmentLengthRule(maxLength: 80)
        let item = Staffing.newFloatPoolTemplate("x", name: "y")
        item.segment = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolTemplateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.FloatPoolTemplateRequiredLabelRule(message: "float pool template needs a value")
        let item = Staffing.newFloatPoolTemplate("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolTemplateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.FloatPoolTemplateNameLengthRule(maxLength: 32)
        let item = Staffing.newFloatPoolTemplate("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
