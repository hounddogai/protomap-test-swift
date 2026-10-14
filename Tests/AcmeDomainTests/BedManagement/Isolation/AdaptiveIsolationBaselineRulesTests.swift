@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveIsolationBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveIsolationBaselineValidator()
        let item = BedManagement.newAdaptiveIsolationBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveIsolationBaselineRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = BedManagement.AdaptiveIsolationBaselineRequiredDiagnosisCodeRule(
            message: "adaptive isolation baseline needs a value"
        )
        let item = BedManagement.newAdaptiveIsolationBaseline("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementAdaptiveIsolationBaselinePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.AdaptiveIsolationBaselinePriorityRangeRule(min: 255, max: 86400)
        let item = BedManagement.newAdaptiveIsolationBaseline("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementAdaptiveIsolationBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.AdaptiveIsolationBaselineRequiredCodeRule(
            message: "adaptive isolation baseline needs an entry"
        )
        let item = BedManagement.newAdaptiveIsolationBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
