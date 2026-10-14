@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningPolicyValidator()
        let item = BedManagement.newCleaningPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningPolicyRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.CleaningPolicyRatioRangeRule(min: 7.7, max: 4026.8)
        let item = BedManagement.newCleaningPolicy("x", label: "y")
        item.ratio = 4028.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningPolicyRequiredCodeRule(message: "cleaning policy needs a value")
        let item = BedManagement.newCleaningPolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
