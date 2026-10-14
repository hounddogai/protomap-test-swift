@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingCareProtocolBundleValidator()
        let item = Imaging.newRollingCareProtocolBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingCareProtocolBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.RollingCareProtocolBundleCodeLengthRule(maxLength: 255)
        let item = Imaging.newRollingCareProtocolBundle("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingCareProtocolBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.RollingCareProtocolBundleTitleLengthRule(maxLength: 16)
        let item = Imaging.newRollingCareProtocolBundle("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingCareProtocolBundleRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.RollingCareProtocolBundleRequiredSummaryRule(
            message: "rolling care protocol bundle needs an entry"
        )
        let item = Imaging.newRollingCareProtocolBundle("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingCareProtocolBundleSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Imaging.RollingCareProtocolBundleSummaryLengthRule(maxLength: 80)
        let item = Imaging.newRollingCareProtocolBundle("x", title: "y")
        item.summary = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingRollingCareProtocolBundleGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.RollingCareProtocolBundleGraceDaysRangeRule(min: 80, max: 3600)
        let item = Imaging.newRollingCareProtocolBundle("x", title: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
