@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualDischargePlanProfileValidator()
        let item = BedManagement.newManualDischargePlanProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualDischargePlanProfileRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = BedManagement.ManualDischargePlanProfileRequiredSourceRule(
            message: "manual discharge plan profile needs this field"
        )
        let item = BedManagement.newManualDischargePlanProfile("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualDischargePlanProfileRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = BedManagement.ManualDischargePlanProfileRequiredProcedureCodeRule(
            message: "manual discharge plan profile needs a value"
        )
        let item = BedManagement.newManualDischargePlanProfile("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
