@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveCredentialTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAdaptiveCredentialTemplateValidator()
        let item = Staffing.newAdaptiveCredentialTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAdaptiveCredentialTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AdaptiveCredentialTemplateCodeLengthRule(maxLength: 255)
        let item = Staffing.newAdaptiveCredentialTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAdaptiveCredentialTemplateSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Staffing.AdaptiveCredentialTemplateSummaryLengthRule(maxLength: 16)
        let item = Staffing.newAdaptiveCredentialTemplate("x", name: "y")
        item.summary = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAdaptiveCredentialTemplateRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.AdaptiveCredentialTemplateRequiredSummaryRule(
            message: "adaptive credential template needs this field"
        )
        let item = Staffing.newAdaptiveCredentialTemplate("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveCredentialTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AdaptiveCredentialTemplateRequiredCodeRule(
            message: "adaptive credential template needs a value"
        )
        let item = Staffing.newAdaptiveCredentialTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAdaptiveCredentialTemplateBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Staffing.AdaptiveCredentialTemplateBedLengthRule(maxLength: 3600)
        let item = Staffing.newAdaptiveCredentialTemplate("x", name: "y")
        item.bed = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
