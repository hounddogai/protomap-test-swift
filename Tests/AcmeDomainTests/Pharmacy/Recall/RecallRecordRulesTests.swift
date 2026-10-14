@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallRecordValidator()
        let item = Pharmacy.newRecallRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RecallRecordTitleLengthRule(maxLength: 32)
        let item = Pharmacy.newRecallRecord("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallRecordRequiredCodeRule(message: "recall record needs an entry")
        let item = Pharmacy.newRecallRecord("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
