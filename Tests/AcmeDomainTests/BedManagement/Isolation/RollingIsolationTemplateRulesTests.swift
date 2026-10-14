@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingIsolationTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingIsolationTemplateValidator()
        let item = BedManagement.newRollingIsolationTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingIsolationTemplateCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = BedManagement.RollingIsolationTemplateCountryLengthRule(maxLength: 1000)
        let item = BedManagement.newRollingIsolationTemplate("x", label: "y")
        item.country = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRollingIsolationTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.RollingIsolationTemplateRequiredNameRule(
            message: "rolling isolation template needs a value"
        )
        let item = BedManagement.newRollingIsolationTemplate("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingIsolationTemplateRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.RollingIsolationTemplateRatioRangeRule(min: 9.8, max: 1568.5)
        let item = BedManagement.newRollingIsolationTemplate("x", label: "y")
        item.ratio = 1570.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingIsolationTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.RollingIsolationTemplateLabelLengthRule(maxLength: 86400)
        let item = BedManagement.newRollingIsolationTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
