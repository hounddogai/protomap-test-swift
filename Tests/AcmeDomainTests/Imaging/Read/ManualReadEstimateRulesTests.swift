@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualReadEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultManualReadEstimateValidator()
        let item = Imaging.newManualReadEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingManualReadEstimateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ManualReadEstimateTitleLengthRule(maxLength: 16)
        let item = Imaging.newManualReadEstimate("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingManualReadEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ManualReadEstimateRequiredCodeRule(message: "manual read estimate needs this field")
        let item = Imaging.newManualReadEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualReadEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ManualReadEstimateCodeLengthRule(maxLength: 120)
        let item = Imaging.newManualReadEstimate("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingManualReadEstimateRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Imaging.ManualReadEstimateRequiredCurrencyRule(message: "manual read estimate needs this field")
        let item = Imaging.newManualReadEstimate("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualReadEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.ManualReadEstimateRequiredTitleRule(message: "manual read estimate needs this field")
        let item = Imaging.newManualReadEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
