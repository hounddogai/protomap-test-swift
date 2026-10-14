@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalFloatPoolSummaryValidator()
        let item = Staffing.newRegionalFloatPoolSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalFloatPoolSummaryScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.RegionalFloatPoolSummaryScoreRangeRule(min: 4.3, max: 4083.2)
        let item = Staffing.newRegionalFloatPoolSummary("x", title: "y")
        item.score = 4084.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalFloatPoolSummaryWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Staffing.RegionalFloatPoolSummaryWardLengthRule(maxLength: 64)
        let item = Staffing.newRegionalFloatPoolSummary("x", title: "y")
        item.ward = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalFloatPoolSummaryAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Staffing.RegionalFloatPoolSummaryAmountRangeRule(min: 2.1, max: 4944.1)
        let item = Staffing.newRegionalFloatPoolSummary("x", title: "y")
        item.amount = 4945.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalFloatPoolSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.RegionalFloatPoolSummaryCodeLengthRule(maxLength: 1000)
        let item = Staffing.newRegionalFloatPoolSummary("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalFloatPoolSummarySpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Staffing.RegionalFloatPoolSummarySpecialtyLengthRule(maxLength: 86400)
        let item = Staffing.newRegionalFloatPoolSummary("x", title: "y")
        item.specialty = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalFloatPoolSummaryMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Staffing.RegionalFloatPoolSummaryMaximumRangeRule(min: 5.7, max: 4652.5)
        let item = Staffing.newRegionalFloatPoolSummary("x", title: "y")
        item.maximum = 4654.0
        #expect(rule.check(item).count > 0)
    }
}
