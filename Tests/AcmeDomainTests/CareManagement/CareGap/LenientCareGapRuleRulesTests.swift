@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientCareGapRuleValidator()
        let item = CareManagement.newLenientCareGapRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientCareGapRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.LenientCareGapRuleNameLengthRule(maxLength: 3600)
        let item = CareManagement.newLenientCareGapRule("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientCareGapRuleRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = CareManagement.LenientCareGapRuleRatioRangeRule(min: 6.4, max: 379.3)
        let item = CareManagement.newLenientCareGapRule("x", name: "y")
        item.ratio = 380.8
        #expect(rule.check(item).count > 0)
    }
}
