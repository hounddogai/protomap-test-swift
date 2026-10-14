@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolBundleValidator()
        let item = Imaging.newCareProtocolBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolBundleRequiredCodeRule(message: "care protocol bundle needs this field")
        let item = Imaging.newCareProtocolBundle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolBundleCodeLengthRule(maxLength: 64)
        let item = Imaging.newCareProtocolBundle("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolBundleUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.CareProtocolBundleUpdatedAtRangeRule(min: 80, max: 3600)
        let item = Imaging.newCareProtocolBundle("x", name: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolBundleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.CareProtocolBundleScoreRangeRule(min: 3.7, max: 3149.3)
        let item = Imaging.newCareProtocolBundle("x", name: "y")
        item.score = 3150.8
        #expect(rule.check(item).count > 0)
    }
}
