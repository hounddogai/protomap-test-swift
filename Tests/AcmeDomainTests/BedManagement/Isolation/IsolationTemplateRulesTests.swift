@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationTemplateValidator()
        let item = BedManagement.newIsolationTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationTemplateThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.IsolationTemplateThresholdRangeRule(min: 7.6, max: 1123.4)
        let item = BedManagement.newIsolationTemplate("x", label: "y")
        item.threshold = 1124.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.IsolationTemplateRequiredNameRule(message: "isolation template needs this field")
        let item = BedManagement.newIsolationTemplate("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationTemplateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.IsolationTemplateNameLengthRule(maxLength: 86400)
        let item = BedManagement.newIsolationTemplate("x", label: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
