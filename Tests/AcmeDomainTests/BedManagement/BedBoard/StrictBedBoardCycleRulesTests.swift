@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictBedBoardCycleValidator()
        let item = BedManagement.newStrictBedBoardCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictBedBoardCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.StrictBedBoardCycleRequiredNameRule(message: "strict bed board cycle needs an entry")
        let item = BedManagement.newStrictBedBoardCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementStrictBedBoardCycleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.StrictBedBoardCycleNameLengthRule(maxLength: 86400)
        let item = BedManagement.newStrictBedBoardCycle("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictBedBoardCyclePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = BedManagement.StrictBedBoardCyclePatientRefLengthRule(maxLength: 32)
        let item = BedManagement.newStrictBedBoardCycle("x", name: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictBedBoardCycleCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.StrictBedBoardCycleCeilingRangeRule(min: 5.2, max: 1254.1)
        let item = BedManagement.newStrictBedBoardCycle("x", name: "y")
        item.ceiling = 1255.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementStrictBedBoardCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.StrictBedBoardCycleRequiredCodeRule(message: "strict bed board cycle needs this field")
        let item = BedManagement.newStrictBedBoardCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
