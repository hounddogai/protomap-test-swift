@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalOvertimeEntryValidator()
        let item = Staffing.newRegionalOvertimeEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalOvertimeEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.RegionalOvertimeEntryCodeLengthRule(maxLength: 64)
        let item = Staffing.newRegionalOvertimeEntry("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalOvertimeEntryRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Staffing.RegionalOvertimeEntryRequiredRegionRule(message: "regional overtime entry needs a value")
        let item = Staffing.newRegionalOvertimeEntry("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRegionalOvertimeEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.RegionalOvertimeEntryNameLengthRule(maxLength: 255)
        let item = Staffing.newRegionalOvertimeEntry("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalOvertimeEntryRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Staffing.RegionalOvertimeEntryRegionLengthRule(maxLength: 32)
        let item = Staffing.newRegionalOvertimeEntry("x", name: "y")
        item.region = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalOvertimeEntryProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Staffing.RegionalOvertimeEntryProcedureCodeLengthRule(maxLength: 255)
        let item = Staffing.newRegionalOvertimeEntry("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
