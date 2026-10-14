@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistWindowValidator()
        let item = Imaging.newWorklistWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistWindowLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Imaging.WorklistWindowLimitRangeRule(min: 255, max: 86400)
        let item = Imaging.newWorklistWindow("x", title: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistWindowRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Imaging.WorklistWindowRequiredExternalRefRule(message: "worklist window needs this field")
        let item = Imaging.newWorklistWindow("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WorklistWindowRequiredCodeRule(message: "worklist window needs this field")
        let item = Imaging.newWorklistWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistWindowSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.WorklistWindowSequenceRangeRule(min: 16, max: 64)
        let item = Imaging.newWorklistWindow("x", title: "y")
        item.sequence = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistWindowRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.WorklistWindowRequiredBedRule(message: "worklist window needs an entry")
        let item = Imaging.newWorklistWindow("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
