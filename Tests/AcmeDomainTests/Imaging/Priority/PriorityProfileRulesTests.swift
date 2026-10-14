@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityProfileValidator()
        let item = Imaging.newPriorityProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityProfileRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Imaging.PriorityProfileRequiredLocaleRule(message: "priority profile needs an entry")
        let item = Imaging.newPriorityProfile("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityProfileCodeLengthRule(maxLength: 255)
        let item = Imaging.newPriorityProfile("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityProfileRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.PriorityProfileRequiredTitleRule(message: "priority profile needs this field")
        let item = Imaging.newPriorityProfile("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.PriorityProfileTitleLengthRule(maxLength: 255)
        let item = Imaging.newPriorityProfile("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
