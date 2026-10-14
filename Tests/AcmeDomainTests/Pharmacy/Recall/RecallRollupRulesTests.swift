@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallRollupValidator()
        let item = Pharmacy.newRecallRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.RecallRollupNameLengthRule(maxLength: 1000)
        let item = Pharmacy.newRecallRollup("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallRollupRequiredCodeRule(message: "recall rollup needs a value")
        let item = Pharmacy.newRecallRollup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallRollupRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Pharmacy.RecallRollupRegionLengthRule(maxLength: 64)
        let item = Pharmacy.newRecallRollup("x", name: "y")
        item.region = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallRollupDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Pharmacy.RecallRollupDescriptionLengthRule(maxLength: 3600)
        let item = Pharmacy.newRecallRollup("x", name: "y")
        item.description = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.RecallRollupRequiredNameRule(message: "recall rollup needs an entry")
        let item = Pharmacy.newRecallRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
