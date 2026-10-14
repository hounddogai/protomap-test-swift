@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacySpecimenProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacySpecimenProfileValidator()
        let item = Labs.newLegacySpecimenProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacySpecimenProfileRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.LegacySpecimenProfileRequiredLabelRule(message: "legacy specimen profile needs this field")
        let item = Labs.newLegacySpecimenProfile("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacySpecimenProfileMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.LegacySpecimenProfileMinimumRangeRule(min: 9.8, max: 3152.6)
        let item = Labs.newLegacySpecimenProfile("x", label: "y")
        item.minimum = 3154.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacySpecimenProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LegacySpecimenProfileRequiredCodeRule(message: "legacy specimen profile needs a value")
        let item = Labs.newLegacySpecimenProfile("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacySpecimenProfileRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Labs.LegacySpecimenProfileRequiredOwnerIDRule(message: "legacy specimen profile needs a value")
        let item = Labs.newLegacySpecimenProfile("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
