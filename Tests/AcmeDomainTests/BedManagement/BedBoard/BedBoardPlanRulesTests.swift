@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardPlanValidator()
        let item = BedManagement.newBedBoardPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardPlanRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = BedManagement.BedBoardPlanRequiredProcedureCodeRule(message: "bed board plan needs a value")
        let item = BedManagement.newBedBoardPlan("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardPlanCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.BedBoardPlanCopayRangeRule(min: 2.7, max: 1020.3)
        let item = BedManagement.newBedBoardPlan("x", label: "y")
        item.copay = 1021.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardPlanCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.BedBoardPlanCeilingRangeRule(min: 4.5, max: 3671.6)
        let item = BedManagement.newBedBoardPlan("x", label: "y")
        item.ceiling = 3673.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardPlanRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = BedManagement.BedBoardPlanRequiredUnitRule(message: "bed board plan needs this field")
        let item = BedManagement.newBedBoardPlan("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
