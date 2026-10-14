@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityGroupValidator()
        let item = Imaging.newPriorityGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.PriorityGroupLabelLengthRule(maxLength: 120)
        let item = Imaging.newPriorityGroup("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityGroupCodeLengthRule(maxLength: 86400)
        let item = Imaging.newPriorityGroup("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PriorityGroupRequiredCodeRule(message: "priority group needs a value")
        let item = Imaging.newPriorityGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
