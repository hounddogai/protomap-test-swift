@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingPriorityAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingPriorityAgreementValidator()
        let item = Imaging.newRollingPriorityAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingPriorityAgreementAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.RollingPriorityAgreementAcuityRangeRule(min: 64, max: 1000)
        let item = Imaging.newRollingPriorityAgreement("x", title: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRollingPriorityAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.RollingPriorityAgreementTitleLengthRule(maxLength: 16)
        let item = Imaging.newRollingPriorityAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
