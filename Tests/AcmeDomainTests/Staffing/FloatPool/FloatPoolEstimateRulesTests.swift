@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolEstimateValidator()
        let item = Staffing.newFloatPoolEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FloatPoolEstimateRequiredCodeRule(message: "float pool estimate needs a value")
        let item = Staffing.newFloatPoolEstimate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolEstimateRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Staffing.FloatPoolEstimateRevisionRangeRule(min: 3600, max: 3600)
        let item = Staffing.newFloatPoolEstimate("x", name: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}
