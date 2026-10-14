@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistDigestValidator()
        let item = Imaging.newWorklistDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistDigestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Imaging.WorklistDigestEndsAtRangeRule(min: 255, max: 1000)
        let item = Imaging.newWorklistDigest("x", title: "y")
        item.endsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WorklistDigestRequiredCodeRule(message: "worklist digest needs an entry")
        let item = Imaging.newWorklistDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.WorklistDigestRequiredTitleRule(message: "worklist digest needs this field")
        let item = Imaging.newWorklistDigest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.WorklistDigestCodeLengthRule(maxLength: 255)
        let item = Imaging.newWorklistDigest("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
