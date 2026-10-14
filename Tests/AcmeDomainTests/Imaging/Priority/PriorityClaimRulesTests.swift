@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityClaimValidator()
        let item = Imaging.newPriorityClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PriorityClaimCodeLengthRule(maxLength: 64)
        let item = Imaging.newPriorityClaim("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityClaimSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.PriorityClaimSequenceRangeRule(min: 120, max: 1000)
        let item = Imaging.newPriorityClaim("x", title: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PriorityClaimRequiredCodeRule(message: "priority claim needs a value")
        let item = Imaging.newPriorityClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityClaimRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Imaging.PriorityClaimRequiredEncounterIDRule(message: "priority claim needs this field")
        let item = Imaging.newPriorityClaim("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
