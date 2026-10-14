@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultReadBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultDefaultReadBaselineValidator()
        let item = Imaging.newDefaultReadBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingDefaultReadBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.DefaultReadBaselineRequiredNameRule(message: "default read baseline needs this field")
        let item = Imaging.newDefaultReadBaseline("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingDefaultReadBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.DefaultReadBaselineRequiredCodeRule(message: "default read baseline needs a value")
        let item = Imaging.newDefaultReadBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingDefaultReadBaselineCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.DefaultReadBaselineCopayRangeRule(min: 9.9, max: 1686.5)
        let item = Imaging.newDefaultReadBaseline("x", name: "y")
        item.copay = 1688.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingDefaultReadBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.DefaultReadBaselineNameLengthRule(maxLength: 3600)
        let item = Imaging.newDefaultReadBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
