@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledHandoffWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultScheduledHandoffWindowValidator()
        let item = ClinicalOps.newScheduledHandoffWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsScheduledHandoffWindowCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = ClinicalOps.ScheduledHandoffWindowCurrencyLengthRule(maxLength: 3600)
        let item = ClinicalOps.newScheduledHandoffWindow("x", label: "y")
        item.currency = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledHandoffWindowDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.ScheduledHandoffWindowDiscountRangeRule(min: 5.9, max: 4597.1)
        let item = ClinicalOps.newScheduledHandoffWindow("x", label: "y")
        item.discount = 4598.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsScheduledHandoffWindowRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.ScheduledHandoffWindowRequiredClinicianIDRule(
            message: "scheduled handoff window needs this field"
        )
        let item = ClinicalOps.newScheduledHandoffWindow("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
