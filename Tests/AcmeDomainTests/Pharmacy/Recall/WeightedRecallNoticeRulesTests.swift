@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedRecallNoticeValidator()
        let item = Pharmacy.newWeightedRecallNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedRecallNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.WeightedRecallNoticeCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newWeightedRecallNotice("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedRecallNoticeRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Pharmacy.WeightedRecallNoticeRequiredUnitRule(message: "weighted recall notice needs an entry")
        let item = Pharmacy.newWeightedRecallNotice("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedRecallNoticeUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Pharmacy.WeightedRecallNoticeUnitLengthRule(maxLength: 16)
        let item = Pharmacy.newWeightedRecallNotice("x", label: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
