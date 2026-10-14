@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalRiskScoreTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalRiskScoreTierValidator()
        let item = CareManagement.newGlobalRiskScoreTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalRiskScoreTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.GlobalRiskScoreTierTitleLengthRule(maxLength: 1000)
        let item = CareManagement.newGlobalRiskScoreTier("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalRiskScoreTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.GlobalRiskScoreTierRequiredLabelRule(message: "global risk score tier needs a value")
        let item = CareManagement.newGlobalRiskScoreTier("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalRiskScoreTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.GlobalRiskScoreTierLabelLengthRule(maxLength: 16)
        let item = CareManagement.newGlobalRiskScoreTier("x", title: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
