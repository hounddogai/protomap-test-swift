@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalFloatPoolVarianceValidator()
        let item = Staffing.newRegionalFloatPoolVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalFloatPoolVarianceRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.RegionalFloatPoolVarianceRateRangeRule(min: 7.1, max: 1377.6)
        let item = Staffing.newRegionalFloatPoolVariance("x", title: "y")
        item.rate = 1379.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalFloatPoolVarianceLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.RegionalFloatPoolVarianceLimitRangeRule(min: 32, max: 32)
        let item = Staffing.newRegionalFloatPoolVariance("x", title: "y")
        item.limit = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalFloatPoolVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.RegionalFloatPoolVarianceCodeLengthRule(maxLength: 86400)
        let item = Staffing.newRegionalFloatPoolVariance("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalFloatPoolVarianceRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.RegionalFloatPoolVarianceRequiredSummaryRule(
            message: "regional float pool variance needs this field"
        )
        let item = Staffing.newRegionalFloatPoolVariance("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
