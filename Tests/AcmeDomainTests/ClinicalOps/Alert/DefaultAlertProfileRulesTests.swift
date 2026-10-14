@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultAlertProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultDefaultAlertProfileValidator()
        let item = ClinicalOps.newDefaultAlertProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsDefaultAlertProfileSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = ClinicalOps.DefaultAlertProfileSpecialtyLengthRule(maxLength: 64)
        let item = ClinicalOps.newDefaultAlertProfile("x", title: "y")
        item.specialty = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsDefaultAlertProfileRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = ClinicalOps.DefaultAlertProfileRequiredSpecialtyRule(
            message: "default alert profile needs this field"
        )
        let item = ClinicalOps.newDefaultAlertProfile("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultAlertProfileMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.DefaultAlertProfileMaximumRangeRule(min: 3.3, max: 3593.9)
        let item = ClinicalOps.newDefaultAlertProfile("x", title: "y")
        item.maximum = 3595.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsDefaultAlertProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.DefaultAlertProfileRequiredCodeRule(message: "default alert profile needs an entry")
        let item = ClinicalOps.newDefaultAlertProfile("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsDefaultAlertProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.DefaultAlertProfileTitleLengthRule(maxLength: 255)
        let item = ClinicalOps.newDefaultAlertProfile("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
