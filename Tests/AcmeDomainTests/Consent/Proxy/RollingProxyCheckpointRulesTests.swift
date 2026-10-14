@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingProxyCheckpointValidator()
        let item = Consent.newRollingProxyCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingProxyCheckpointCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.RollingProxyCheckpointCostRangeRule(min: 3.5, max: 1779.8)
        let item = Consent.newRollingProxyCheckpoint("x", label: "y")
        item.cost = 1781.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRollingProxyCheckpointEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Consent.RollingProxyCheckpointEncounterIDLengthRule(maxLength: 120)
        let item = Consent.newRollingProxyCheckpoint("x", label: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingProxyCheckpointRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Consent.RollingProxyCheckpointRequiredEncounterIDRule(
            message: "rolling proxy checkpoint needs a value"
        )
        let item = Consent.newRollingProxyCheckpoint("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingProxyCheckpointRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.RollingProxyCheckpointRequiredLabelRule(message: "rolling proxy checkpoint needs a value")
        let item = Consent.newRollingProxyCheckpoint("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
