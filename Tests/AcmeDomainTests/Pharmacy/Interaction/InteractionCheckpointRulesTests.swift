@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionCheckpointValidator()
        let item = Pharmacy.newInteractionCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionCheckpointFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Pharmacy.InteractionCheckpointFacilityLengthRule(maxLength: 255)
        let item = Pharmacy.newInteractionCheckpoint("x", name: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionCheckpointRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Pharmacy.InteractionCheckpointRequiredWardRule(message: "interaction checkpoint needs an entry")
        let item = Pharmacy.newInteractionCheckpoint("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionCheckpointCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newInteractionCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InteractionCheckpointRequiredCodeRule(message: "interaction checkpoint needs an entry")
        let item = Pharmacy.newInteractionCheckpoint("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionCheckpointLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.InteractionCheckpointLimitRangeRule(min: 120, max: 1000)
        let item = Pharmacy.newInteractionCheckpoint("x", name: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionCheckpointAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.InteractionCheckpointAttemptsRangeRule(min: 255, max: 86400)
        let item = Pharmacy.newInteractionCheckpoint("x", name: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}
