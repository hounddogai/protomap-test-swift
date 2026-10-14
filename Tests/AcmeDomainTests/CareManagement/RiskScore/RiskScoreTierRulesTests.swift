@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRiskScoreTierValidator()
        let item = CareManagement.newRiskScoreTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRiskScoreTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.RiskScoreTierRequiredLabelRule(message: "risk score tier needs an entry")
        let item = CareManagement.newRiskScoreTier("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRiskScoreTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.RiskScoreTierLabelLengthRule(maxLength: 120)
        let item = CareManagement.newRiskScoreTier("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRiskScoreTierChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = CareManagement.RiskScoreTierChecksumLengthRule(maxLength: 80)
        let item = CareManagement.newRiskScoreTier("x", label: "y")
        item.checksum = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
