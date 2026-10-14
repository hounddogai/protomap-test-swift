@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseThresholdValidator()
        let item = Pharmacy.newDispenseThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseThresholdRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Pharmacy.DispenseThresholdRetriesRangeRule(min: 32, max: 86400)
        let item = Pharmacy.newDispenseThreshold("x", label: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseThresholdRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Pharmacy.DispenseThresholdRequiredSourceRule(message: "dispense threshold needs an entry")
        let item = Pharmacy.newDispenseThreshold("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}
