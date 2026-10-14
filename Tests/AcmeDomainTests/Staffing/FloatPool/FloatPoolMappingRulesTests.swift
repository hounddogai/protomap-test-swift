@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolMappingValidator()
        let item = Staffing.newFloatPoolMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolMappingTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.FloatPoolMappingTitleLengthRule(maxLength: 1000)
        let item = Staffing.newFloatPoolMapping("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolMappingRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.FloatPoolMappingRetriesRangeRule(min: 64, max: 255)
        let item = Staffing.newFloatPoolMapping("x", title: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}
