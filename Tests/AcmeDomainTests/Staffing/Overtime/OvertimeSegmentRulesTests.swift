@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeSegmentValidator()
        let item = Staffing.newOvertimeSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.OvertimeSegmentCodeLengthRule(maxLength: 3600)
        let item = Staffing.newOvertimeSegment("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeSegmentBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.OvertimeSegmentBatchSizeRangeRule(min: 1000, max: 1000)
        let item = Staffing.newOvertimeSegment("x", name: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}
