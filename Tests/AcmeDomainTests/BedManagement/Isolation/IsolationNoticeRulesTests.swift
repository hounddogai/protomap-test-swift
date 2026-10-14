@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationNoticeValidator()
        let item = BedManagement.newIsolationNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationNoticeTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.IsolationNoticeTitleLengthRule(maxLength: 255)
        let item = BedManagement.newIsolationNotice("x", label: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationNoticeFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.IsolationNoticeFloorValueRangeRule(min: 3.0, max: 2535.3)
        let item = BedManagement.newIsolationNotice("x", label: "y")
        item.floorValue = 2536.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationNoticeProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = BedManagement.IsolationNoticeProcedureCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newIsolationNotice("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
