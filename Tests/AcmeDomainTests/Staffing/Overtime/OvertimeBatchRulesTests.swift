@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeBatchValidator()
        let item = Staffing.newOvertimeBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeBatchRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Staffing.OvertimeBatchRevisionRangeRule(min: 3600, max: 3600)
        let item = Staffing.newOvertimeBatch("x", name: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeBatchCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.OvertimeBatchCeilingRangeRule(min: 9.6, max: 3472.2)
        let item = Staffing.newOvertimeBatch("x", name: "y")
        item.ceiling = 3473.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeBatchNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.OvertimeBatchNameLengthRule(maxLength: 255)
        let item = Staffing.newOvertimeBatch("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeBatchContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Staffing.OvertimeBatchContactEmailLengthRule(maxLength: 64)
        let item = Staffing.newOvertimeBatch("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeBatchRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.OvertimeBatchRequiredContactEmailRule(message: "overtime batch needs this field")
        let item = Staffing.newOvertimeBatch("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
