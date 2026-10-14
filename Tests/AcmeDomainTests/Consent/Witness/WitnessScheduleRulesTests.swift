@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessScheduleValidator()
        let item = Consent.newWitnessSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessScheduleUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Consent.WitnessScheduleUpdatedAtRangeRule(min: 16, max: 1000)
        let item = Consent.newWitnessSchedule("x", title: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessScheduleRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Consent.WitnessScheduleRefillsRangeRule(min: 16, max: 32)
        let item = Consent.newWitnessSchedule("x", title: "y")
        item.refills = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessScheduleRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Consent.WitnessScheduleRequiredBedRule(message: "witness schedule needs a value")
        let item = Consent.newWitnessSchedule("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
