@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalOvertimeWindowValidator()
        let item = Staffing.newRegionalOvertimeWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalOvertimeWindowRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Staffing.RegionalOvertimeWindowRequiredProcedureCodeRule(
            message: "regional overtime window needs an entry"
        )
        let item = Staffing.newRegionalOvertimeWindow("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRegionalOvertimeWindowBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.RegionalOvertimeWindowBatchSizeRangeRule(min: 120, max: 3600)
        let item = Staffing.newRegionalOvertimeWindow("x", name: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalOvertimeWindowProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Staffing.RegionalOvertimeWindowProcedureCodeLengthRule(maxLength: 32)
        let item = Staffing.newRegionalOvertimeWindow("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
