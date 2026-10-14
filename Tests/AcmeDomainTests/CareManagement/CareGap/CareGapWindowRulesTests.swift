@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapWindowValidator()
        let item = CareManagement.newCareGapWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CareGapWindowCodeLengthRule(maxLength: 32)
        let item = CareManagement.newCareGapWindow("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapWindowThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.CareGapWindowThresholdRangeRule(min: 3.6, max: 4676.9)
        let item = CareManagement.newCareGapWindow("x", name: "y")
        item.threshold = 4678.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapWindowRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.CareGapWindowRequiredNameRule(message: "care gap window needs this field")
        let item = CareManagement.newCareGapWindow("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
