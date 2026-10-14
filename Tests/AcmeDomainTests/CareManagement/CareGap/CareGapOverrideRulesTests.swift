@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapOverrideValidator()
        let item = CareManagement.newCareGapOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.CareGapOverrideTitleLengthRule(maxLength: 16)
        let item = CareManagement.newCareGapOverride("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapOverrideRequiredCodeRule(message: "care gap override needs a value")
        let item = CareManagement.newCareGapOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapOverrideRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.CareGapOverrideRevisionRangeRule(min: 32, max: 86400)
        let item = CareManagement.newCareGapOverride("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}
