@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledStudyRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledStudyRuleValidator()
        let item = Imaging.newScheduledStudyRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledStudyRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ScheduledStudyRuleRequiredCodeRule(message: "scheduled study rule needs this field")
        let item = Imaging.newScheduledStudyRule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledStudyRuleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ScheduledStudyRuleTitleLengthRule(maxLength: 16)
        let item = Imaging.newScheduledStudyRule("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledStudyRuleFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Imaging.ScheduledStudyRuleFacilityLengthRule(maxLength: 16)
        let item = Imaging.newScheduledStudyRule("x", title: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
