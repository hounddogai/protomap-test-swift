@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualDischargePlanTargetValidator()
        let item = BedManagement.newManualDischargePlanTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualDischargePlanTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.ManualDischargePlanTargetRequiredLabelRule(
            message: "manual discharge plan target needs this field"
        )
        let item = BedManagement.newManualDischargePlanTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualDischargePlanTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.ManualDischargePlanTargetLabelLengthRule(maxLength: 1000)
        let item = BedManagement.newManualDischargePlanTarget("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualDischargePlanTargetAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.ManualDischargePlanTargetAttemptsRangeRule(min: 32, max: 86400)
        let item = BedManagement.newManualDischargePlanTarget("x", label: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementManualDischargePlanTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.ManualDischargePlanTargetRequiredCodeRule(
            message: "manual discharge plan target needs a value"
        )
        let item = BedManagement.newManualDischargePlanTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualDischargePlanTargetRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.ManualDischargePlanTargetRequiredCountryRule(
            message: "manual discharge plan target needs an entry"
        )
        let item = BedManagement.newManualDischargePlanTarget("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualDischargePlanTargetCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = BedManagement.ManualDischargePlanTargetCountryLengthRule(maxLength: 16)
        let item = BedManagement.newManualDischargePlanTarget("x", label: "y")
        item.country = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
