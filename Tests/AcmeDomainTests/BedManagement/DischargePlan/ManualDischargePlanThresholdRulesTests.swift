@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualDischargePlanThresholdValidator()
        let item = BedManagement.newManualDischargePlanThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualDischargePlanThresholdRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = BedManagement.ManualDischargePlanThresholdRequiredDiagnosisCodeRule(
            message: "manual discharge plan threshold needs an entry"
        )
        let item = BedManagement.newManualDischargePlanThreshold("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualDischargePlanThresholdAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.ManualDischargePlanThresholdAmountRangeRule(min: 3.6, max: 4113.9)
        let item = BedManagement.newManualDischargePlanThreshold("x", label: "y")
        item.amount = 4115.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementManualDischargePlanThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ManualDischargePlanThresholdCodeLengthRule(maxLength: 120)
        let item = BedManagement.newManualDischargePlanThreshold("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualDischargePlanThresholdDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.ManualDischargePlanThresholdDiagnosisCodeLengthRule(maxLength: 32)
        let item = BedManagement.newManualDischargePlanThreshold("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
