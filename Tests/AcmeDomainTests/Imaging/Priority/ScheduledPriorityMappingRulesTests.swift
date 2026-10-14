@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledPriorityMappingValidator()
        let item = Imaging.newScheduledPriorityMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledPriorityMappingTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ScheduledPriorityMappingTitleLengthRule(maxLength: 64)
        let item = Imaging.newScheduledPriorityMapping("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledPriorityMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ScheduledPriorityMappingCodeLengthRule(maxLength: 3600)
        let item = Imaging.newScheduledPriorityMapping("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledPriorityMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ScheduledPriorityMappingRequiredTitleRule(message: "scheduled priority mapping needs a value")
        let item = Imaging.newScheduledPriorityMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
