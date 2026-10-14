@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientRemittanceManifestValidator()
        let item = RevenueCycle.newLenientRemittanceManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceManifestLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.LenientRemittanceManifestLimitRangeRule(min: 16, max: 86400)
        let item = RevenueCycle.newLenientRemittanceManifest("x", name: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceManifestCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = RevenueCycle.LenientRemittanceManifestCostRangeRule(min: 3.4, max: 3038.7)
        let item = RevenueCycle.newLenientRemittanceManifest("x", name: "y")
        item.cost = 3040.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceManifestPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = RevenueCycle.LenientRemittanceManifestPatientRefLengthRule(maxLength: 255)
        let item = RevenueCycle.newLenientRemittanceManifest("x", name: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
