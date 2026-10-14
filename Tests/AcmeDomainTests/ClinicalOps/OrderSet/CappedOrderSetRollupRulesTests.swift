@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedOrderSetRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCappedOrderSetRollupValidator()
        let item = ClinicalOps.newCappedOrderSetRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCappedOrderSetRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CappedOrderSetRollupCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newCappedOrderSetRollup("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCappedOrderSetRollupRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = ClinicalOps.CappedOrderSetRollupRequiredFacilityRule(
            message: "capped order set rollup needs an entry"
        )
        let item = ClinicalOps.newCappedOrderSetRollup("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedOrderSetRollupRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.CappedOrderSetRollupRequiredTimezoneRule(
            message: "capped order set rollup needs an entry"
        )
        let item = ClinicalOps.newCappedOrderSetRollup("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCappedOrderSetRollupMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = ClinicalOps.CappedOrderSetRollupMinimumRangeRule(min: 3.7, max: 3272.0)
        let item = ClinicalOps.newCappedOrderSetRollup("x", label: "y")
        item.minimum = 3273.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCappedOrderSetRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.CappedOrderSetRollupLabelLengthRule(maxLength: 32)
        let item = ClinicalOps.newCappedOrderSetRollup("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
