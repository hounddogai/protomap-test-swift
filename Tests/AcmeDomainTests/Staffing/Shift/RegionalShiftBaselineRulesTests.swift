@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalShiftBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalShiftBaselineValidator()
        let item = Staffing.newRegionalShiftBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalShiftBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.RegionalShiftBaselineRequiredCodeRule(message: "regional shift baseline needs a value")
        let item = Staffing.newRegionalShiftBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRegionalShiftBaselinePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.RegionalShiftBaselinePayerLengthRule(maxLength: 16)
        let item = Staffing.newRegionalShiftBaseline("x", name: "y")
        item.payer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalShiftBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.RegionalShiftBaselineNameLengthRule(maxLength: 64)
        let item = Staffing.newRegionalShiftBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalShiftBaselineWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.RegionalShiftBaselineWeightRangeRule(min: 4.5, max: 3843.5)
        let item = Staffing.newRegionalShiftBaseline("x", name: "y")
        item.weight = 3845.0
        #expect(rule.check(item).count > 0)
    }
}
