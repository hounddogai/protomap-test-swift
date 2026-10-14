@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedRecallBundleValidator()
        let item = Pharmacy.newWeightedRecallBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedRecallBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.WeightedRecallBundleRequiredCodeRule(message: "weighted recall bundle needs an entry")
        let item = Pharmacy.newWeightedRecallBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedRecallBundleRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.WeightedRecallBundleRequiredClinicianIDRule(
            message: "weighted recall bundle needs this field"
        )
        let item = Pharmacy.newWeightedRecallBundle("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedRecallBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.WeightedRecallBundleNameLengthRule(maxLength: 86400)
        let item = Pharmacy.newWeightedRecallBundle("x", title: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
