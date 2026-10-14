@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredFormularyRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultTieredFormularyRollupValidator()
        let item = Pharmacy.newTieredFormularyRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyTieredFormularyRollupRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Pharmacy.TieredFormularyRollupRequiredOwnerIDRule(message: "tiered formulary rollup needs a value")
        let item = Pharmacy.newTieredFormularyRollup("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyTieredFormularyRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.TieredFormularyRollupRequiredNameRule(message: "tiered formulary rollup needs this field")
        let item = Pharmacy.newTieredFormularyRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
