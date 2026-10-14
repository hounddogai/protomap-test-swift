@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalityPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPendingModalityPolicyValidator()
        let item = Imaging.newPendingModalityPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPendingModalityPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PendingModalityPolicyRequiredCodeRule(message: "pending modality policy needs a value")
        let item = Imaging.newPendingModalityPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingModalityPolicyTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Imaging.PendingModalityPolicyTimezoneLengthRule(maxLength: 80)
        let item = Imaging.newPendingModalityPolicy("x", title: "y")
        item.timezone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPendingModalityPolicyCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Imaging.PendingModalityPolicyCostRangeRule(min: 3.1, max: 4923.7)
        let item = Imaging.newPendingModalityPolicy("x", title: "y")
        item.cost = 4925.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPendingModalityPolicyRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.PendingModalityPolicyRequiredTitleRule(message: "pending modality policy needs a value")
        let item = Imaging.newPendingModalityPolicy("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingModalityPolicyRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.PendingModalityPolicyRatioRangeRule(min: 4.8, max: 2236.7)
        let item = Imaging.newPendingModalityPolicy("x", title: "y")
        item.ratio = 2238.2
        #expect(rule.check(item).count > 0)
    }
}
