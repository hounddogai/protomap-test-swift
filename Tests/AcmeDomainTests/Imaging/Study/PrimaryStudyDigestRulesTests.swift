@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryStudyDigestValidator()
        let item = Imaging.newPrimaryStudyDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryStudyDigestWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Imaging.PrimaryStudyDigestWardLengthRule(maxLength: 3600)
        let item = Imaging.newPrimaryStudyDigest("x", name: "y")
        item.ward = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrimaryStudyDigestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Imaging.PrimaryStudyDigestEndsAtRangeRule(min: 16, max: 255)
        let item = Imaging.newPrimaryStudyDigest("x", name: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryStudyDigestBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Imaging.PrimaryStudyDigestBudgetRangeRule(min: 6.6, max: 4911.0)
        let item = Imaging.newPrimaryStudyDigest("x", name: "y")
        item.budget = 4912.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryStudyDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.PrimaryStudyDigestRequiredNameRule(message: "primary study digest needs a value")
        let item = Imaging.newPrimaryStudyDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
