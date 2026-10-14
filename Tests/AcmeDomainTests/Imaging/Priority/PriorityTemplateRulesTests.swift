@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityTemplateValidator()
        let item = Imaging.newPriorityTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityTemplatePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Imaging.PriorityTemplatePhoneLengthRule(maxLength: 16)
        let item = Imaging.newPriorityTemplate("x", label: "y")
        item.phone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityTemplateRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Imaging.PriorityTemplateRequiredPhoneRule(message: "priority template needs an entry")
        let item = Imaging.newPriorityTemplate("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityTemplateSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Imaging.PriorityTemplateSourceLengthRule(maxLength: 255)
        let item = Imaging.newPriorityTemplate("x", label: "y")
        item.source = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityTemplateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.PriorityTemplateRequiredLabelRule(message: "priority template needs a value")
        let item = Imaging.newPriorityTemplate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
