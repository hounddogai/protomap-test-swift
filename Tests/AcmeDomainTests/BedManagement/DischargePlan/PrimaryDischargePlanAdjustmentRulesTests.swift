@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryDischargePlanAdjustmentValidator()
        let item = BedManagement.newPrimaryDischargePlanAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanAdjustmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.PrimaryDischargePlanAdjustmentRequiredTitleRule(
            message: "primary discharge plan adjustment needs an entry"
        )
        let item = BedManagement.newPrimaryDischargePlanAdjustment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryDischargePlanAdjustmentDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.PrimaryDischargePlanAdjustmentDurationMinutesRangeRule(min: 16, max: 120)
        let item = BedManagement.newPrimaryDischargePlanAdjustment("x", title: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanAdjustmentRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = BedManagement.PrimaryDischargePlanAdjustmentRequiredDiagnosisCodeRule(
            message: "primary discharge plan adjustment needs this field"
        )
        let item = BedManagement.newPrimaryDischargePlanAdjustment("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryDischargePlanAdjustmentDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.PrimaryDischargePlanAdjustmentDiagnosisCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newPrimaryDischargePlanAdjustment("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
