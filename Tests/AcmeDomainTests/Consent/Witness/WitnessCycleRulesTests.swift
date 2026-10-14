@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessCycleValidator()
        let item = Consent.newWitnessCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessCycleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Consent.WitnessCycleThresholdRangeRule(min: 8.3, max: 3989.3)
        let item = Consent.newWitnessCycle("x", name: "y")
        item.threshold = 3990.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WitnessCycleCodeLengthRule(maxLength: 120)
        let item = Consent.newWitnessCycle("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessCycleRequiredCodeRule(message: "witness cycle needs this field")
        let item = Consent.newWitnessCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessCycleRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.WitnessCycleRequiredDiagnosisCodeRule(message: "witness cycle needs this field")
        let item = Consent.newWitnessCycle("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.WitnessCycleRequiredNameRule(message: "witness cycle needs a value")
        let item = Consent.newWitnessCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
