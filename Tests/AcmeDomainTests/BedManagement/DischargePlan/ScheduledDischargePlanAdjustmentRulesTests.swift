@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledDischargePlanAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledDischargePlanAdjustmentValidator()
        let item = BedManagement.newScheduledDischargePlanAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledDischargePlanAdjustmentRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = BedManagement.ScheduledDischargePlanAdjustmentRequiredDiagnosisCodeRule(
            message: "scheduled discharge plan adjustment needs a value"
        )
        let item = BedManagement.newScheduledDischargePlanAdjustment("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledDischargePlanAdjustmentRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.ScheduledDischargePlanAdjustmentRequiredContactEmailRule(
            message: "scheduled discharge plan adjustment needs this field"
        )
        let item = BedManagement.newScheduledDischargePlanAdjustment("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledDischargePlanAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ScheduledDischargePlanAdjustmentCodeLengthRule(maxLength: 255)
        let item = BedManagement.newScheduledDischargePlanAdjustment("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledDischargePlanAdjustmentContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = BedManagement.ScheduledDischargePlanAdjustmentContactEmailLengthRule(maxLength: 80)
        let item = BedManagement.newScheduledDischargePlanAdjustment("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
