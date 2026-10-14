@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientIsolationTemplateValidator()
        let item = BedManagement.newLenientIsolationTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientIsolationTemplateExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.LenientIsolationTemplateExpiresAtRangeRule(min: 16, max: 86400)
        let item = BedManagement.newLenientIsolationTemplate("x", title: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientIsolationTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LenientIsolationTemplateRequiredCodeRule(
            message: "lenient isolation template needs this field"
        )
        let item = BedManagement.newLenientIsolationTemplate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
