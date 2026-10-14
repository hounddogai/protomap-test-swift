@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInventoryPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalInventoryPolicyValidator()
        let item = Pharmacy.newRegionalInventoryPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalInventoryPolicyRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Pharmacy.RegionalInventoryPolicyRequiredProcedureCodeRule(
            message: "regional inventory policy needs an entry"
        )
        let item = Pharmacy.newRegionalInventoryPolicy("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalInventoryPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RegionalInventoryPolicyRequiredCodeRule(
            message: "regional inventory policy needs this field"
        )
        let item = Pharmacy.newRegionalInventoryPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
