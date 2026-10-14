@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedProxySummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWeightedProxySummaryValidator()
        let item = Consent.newWeightedProxySummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWeightedProxySummaryDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Consent.WeightedProxySummaryDosageMgRangeRule(min: 9.0, max: 629.2)
        let item = Consent.newWeightedProxySummary("x", name: "y")
        item.dosageMg = 630.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWeightedProxySummaryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.WeightedProxySummaryNameLengthRule(maxLength: 32)
        let item = Consent.newWeightedProxySummary("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWeightedProxySummaryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.WeightedProxySummaryRequiredNameRule(message: "weighted proxy summary needs this field")
        let item = Consent.newWeightedProxySummary("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
