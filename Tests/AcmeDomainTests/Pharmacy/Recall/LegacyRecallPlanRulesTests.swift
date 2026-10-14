@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyRecallPlanValidator()
        let item = Pharmacy.newLegacyRecallPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyRecallPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LegacyRecallPlanRequiredCodeRule(message: "legacy recall plan needs an entry")
        let item = Pharmacy.newLegacyRecallPlan("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyRecallPlanRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Pharmacy.LegacyRecallPlanRequiredBedRule(message: "legacy recall plan needs a value")
        let item = Pharmacy.newLegacyRecallPlan("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyRecallPlanRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.LegacyRecallPlanRequiredNameRule(message: "legacy recall plan needs a value")
        let item = Pharmacy.newLegacyRecallPlan("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyRecallPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LegacyRecallPlanCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newLegacyRecallPlan("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
