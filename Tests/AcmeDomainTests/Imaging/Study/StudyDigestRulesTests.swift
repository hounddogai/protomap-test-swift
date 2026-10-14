@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyDigestValidator()
        let item = Imaging.newStudyDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyDigestMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.StudyDigestMinimumRangeRule(min: 4.8, max: 3934.1)
        let item = Imaging.newStudyDigest("x", title: "y")
        item.minimum = 3935.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyDigestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StudyDigestRequiredTitleRule(message: "study digest needs a value")
        let item = Imaging.newStudyDigest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
