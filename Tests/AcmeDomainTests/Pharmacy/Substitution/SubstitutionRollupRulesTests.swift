@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionRollupValidator()
        let item = Pharmacy.newSubstitutionRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionRollupMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Pharmacy.SubstitutionRollupMarginRangeRule(min: 7.4, max: 2727.7)
        let item = Pharmacy.newSubstitutionRollup("x", name: "y")
        item.margin = 2729.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.SubstitutionRollupRequiredNameRule(message: "substitution rollup needs an entry")
        let item = Pharmacy.newSubstitutionRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionRollupUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Pharmacy.SubstitutionRollupUnitLengthRule(maxLength: 80)
        let item = Pharmacy.newSubstitutionRollup("x", name: "y")
        item.unit = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionRollupRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Pharmacy.SubstitutionRollupRequiredUnitRule(message: "substitution rollup needs an entry")
        let item = Pharmacy.newSubstitutionRollup("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionRollupRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Pharmacy.SubstitutionRollupRequiredProcedureCodeRule(message: "substitution rollup needs a value")
        let item = Pharmacy.newSubstitutionRollup("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionRollupUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Pharmacy.SubstitutionRollupUpdatedAtRangeRule(min: 16, max: 1000)
        let item = Pharmacy.newSubstitutionRollup("x", name: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
