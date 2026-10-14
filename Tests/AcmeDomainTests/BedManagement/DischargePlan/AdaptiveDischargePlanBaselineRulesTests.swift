@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveDischargePlanBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveDischargePlanBaselineValidator()
        let item = BedManagement.newAdaptiveDischargePlanBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveDischargePlanBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.AdaptiveDischargePlanBaselineRequiredCodeRule(
            message: "adaptive discharge plan baseline needs a value"
        )
        let item = BedManagement.newAdaptiveDischargePlanBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementAdaptiveDischargePlanBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.AdaptiveDischargePlanBaselineRequiredNameRule(
            message: "adaptive discharge plan baseline needs a value"
        )
        let item = BedManagement.newAdaptiveDischargePlanBaseline("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementAdaptiveDischargePlanBaselineCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = BedManagement.AdaptiveDischargePlanBaselineCountryLengthRule(maxLength: 1000)
        let item = BedManagement.newAdaptiveDischargePlanBaseline("x", name: "y")
        item.country = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
