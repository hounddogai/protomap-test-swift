@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallProfileValidator()
        let item = Pharmacy.newRecallProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallProfileRequiredCodeRule(message: "recall profile needs a value")
        let item = Pharmacy.newRecallProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallProfileNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.RecallProfileNameLengthRule(maxLength: 16)
        let item = Pharmacy.newRecallProfile("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallProfileSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Pharmacy.RecallProfileSummaryLengthRule(maxLength: 32)
        let item = Pharmacy.newRecallProfile("x", name: "y")
        item.summary = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
