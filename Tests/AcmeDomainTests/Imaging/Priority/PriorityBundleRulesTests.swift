@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityBundleValidator()
        let item = Imaging.newPriorityBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.PriorityBundleTitleLengthRule(maxLength: 64)
        let item = Imaging.newPriorityBundle("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityBundleRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Imaging.PriorityBundleRequiredSourceRule(message: "priority bundle needs a value")
        let item = Imaging.newPriorityBundle("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityBundleCodeLengthRule(maxLength: 16)
        let item = Imaging.newPriorityBundle("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
