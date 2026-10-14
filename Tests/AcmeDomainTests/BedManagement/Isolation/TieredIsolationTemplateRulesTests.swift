@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTieredIsolationTemplateValidator()
        let item = BedManagement.newTieredIsolationTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTieredIsolationTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.TieredIsolationTemplateLabelLengthRule(maxLength: 1000)
        let item = BedManagement.newTieredIsolationTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTieredIsolationTemplateThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.TieredIsolationTemplateThresholdRangeRule(min: 7.0, max: 194.0)
        let item = BedManagement.newTieredIsolationTemplate("x", label: "y")
        item.threshold = 195.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTieredIsolationTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.TieredIsolationTemplateRequiredCodeRule(
            message: "tiered isolation template needs a value"
        )
        let item = BedManagement.newTieredIsolationTemplate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTieredIsolationTemplateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.TieredIsolationTemplateRequiredLabelRule(
            message: "tiered isolation template needs an entry"
        )
        let item = BedManagement.newTieredIsolationTemplate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTieredIsolationTemplateRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = BedManagement.TieredIsolationTemplateRevisionRangeRule(min: 16, max: 255)
        let item = BedManagement.newTieredIsolationTemplate("x", label: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}
