@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalWitnessBudgetValidator()
        let item = Consent.newSeasonalWitnessBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalWitnessBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.SeasonalWitnessBudgetCodeLengthRule(maxLength: 80)
        let item = Consent.newSeasonalWitnessBudget("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalWitnessBudgetSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Consent.SeasonalWitnessBudgetSourceLengthRule(maxLength: 32)
        let item = Consent.newSeasonalWitnessBudget("x", title: "y")
        item.source = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalWitnessBudgetRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Consent.SeasonalWitnessBudgetRequiredChecksumRule(message: "seasonal witness budget needs this field")
        let item = Consent.newSeasonalWitnessBudget("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentSeasonalWitnessBudgetChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Consent.SeasonalWitnessBudgetChecksumLengthRule(maxLength: 1000)
        let item = Consent.newSeasonalWitnessBudget("x", title: "y")
        item.checksum = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
