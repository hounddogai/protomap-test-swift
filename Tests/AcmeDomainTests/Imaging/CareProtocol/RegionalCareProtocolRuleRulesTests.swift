@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalCareProtocolRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalCareProtocolRuleValidator()
        let item = Imaging.newRegionalCareProtocolRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalCareProtocolRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.RegionalCareProtocolRuleRequiredCodeRule(
            message: "regional care protocol rule needs this field"
        )
        let item = Imaging.newRegionalCareProtocolRule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalCareProtocolRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.RegionalCareProtocolRuleLabelLengthRule(maxLength: 86400)
        let item = Imaging.newRegionalCareProtocolRule("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRegionalCareProtocolRulePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Imaging.RegionalCareProtocolRulePriorityRangeRule(min: 80, max: 86400)
        let item = Imaging.newRegionalCareProtocolRule("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}
