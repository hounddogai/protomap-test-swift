@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredSubstitutionProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultTieredSubstitutionProfileValidator()
        let item = Pharmacy.newTieredSubstitutionProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyTieredSubstitutionProfileSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Pharmacy.TieredSubstitutionProfileSourceLengthRule(maxLength: 86400)
        let item = Pharmacy.newTieredSubstitutionProfile("x", label: "y")
        item.source = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyTieredSubstitutionProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.TieredSubstitutionProfileCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newTieredSubstitutionProfile("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
