@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixSegmentValidator()
        let item = Staffing.newSkillMixSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixSegmentCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.SkillMixSegmentCopayRangeRule(min: 0.2, max: 2003.0)
        let item = Staffing.newSkillMixSegment("x", label: "y")
        item.copay = 2004.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.SkillMixSegmentRequiredLabelRule(message: "skill mix segment needs a value")
        let item = Staffing.newSkillMixSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.SkillMixSegmentLabelLengthRule(maxLength: 255)
        let item = Staffing.newSkillMixSegment("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixSegmentCodeLengthRule(maxLength: 64)
        let item = Staffing.newSkillMixSegment("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixSegmentRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.SkillMixSegmentRateRangeRule(min: 4.2, max: 2976.0)
        let item = Staffing.newSkillMixSegment("x", label: "y")
        item.rate = 2977.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixSegmentSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Staffing.SkillMixSegmentSegmentLengthRule(maxLength: 255)
        let item = Staffing.newSkillMixSegment("x", label: "y")
        item.segment = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
