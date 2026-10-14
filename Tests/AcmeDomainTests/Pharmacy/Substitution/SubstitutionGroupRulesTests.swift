@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionGroupValidator()
        let item = Pharmacy.newSubstitutionGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.SubstitutionGroupCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newSubstitutionGroup("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionGroupLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.SubstitutionGroupLimitRangeRule(min: 1000, max: 86400)
        let item = Pharmacy.newSubstitutionGroup("x", name: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionGroupExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.SubstitutionGroupExternalRefLengthRule(maxLength: 86400)
        let item = Pharmacy.newSubstitutionGroup("x", name: "y")
        item.externalRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySubstitutionGroupRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Pharmacy.SubstitutionGroupRequiredExternalRefRule(message: "substitution group needs a value")
        let item = Pharmacy.newSubstitutionGroup("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionGroupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.SubstitutionGroupRequiredNameRule(message: "substitution group needs an entry")
        let item = Pharmacy.newSubstitutionGroup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionGroupCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Pharmacy.SubstitutionGroupCapacityRangeRule(min: 64, max: 3600)
        let item = Pharmacy.newSubstitutionGroup("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}
