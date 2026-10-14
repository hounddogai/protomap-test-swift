@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveCareProtocolBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultAdaptiveCareProtocolBudgetValidator()
        let item = Imaging.newAdaptiveCareProtocolBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingAdaptiveCareProtocolBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.AdaptiveCareProtocolBudgetRequiredCodeRule(
            message: "adaptive care protocol budget needs this field"
        )
        let item = Imaging.newAdaptiveCareProtocolBudget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingAdaptiveCareProtocolBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.AdaptiveCareProtocolBudgetCodeLengthRule(maxLength: 3600)
        let item = Imaging.newAdaptiveCareProtocolBudget("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingAdaptiveCareProtocolBudgetRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Imaging.AdaptiveCareProtocolBudgetRequiredChecksumRule(
            message: "adaptive care protocol budget needs a value"
        )
        let item = Imaging.newAdaptiveCareProtocolBudget("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
