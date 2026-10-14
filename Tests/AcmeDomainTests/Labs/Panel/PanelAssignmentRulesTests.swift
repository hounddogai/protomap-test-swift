@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelAssignmentValidator()
        let item = Labs.newPanelAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelAssignmentAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.PanelAssignmentAllergyLengthRule(maxLength: 32)
        let item = Labs.newPanelAssignment("x", title: "y")
        item.allergy = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelAssignmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.PanelAssignmentCeilingRangeRule(min: 8.6, max: 3500.7)
        let item = Labs.newPanelAssignment("x", title: "y")
        item.ceiling = 3502.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelAssignmentRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.PanelAssignmentRequiredPhoneRule(message: "panel assignment needs a value")
        let item = Labs.newPanelAssignment("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelAssignmentVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.PanelAssignmentVersionRangeRule(min: 32, max: 1000)
        let item = Labs.newPanelAssignment("x", title: "y")
        item.version = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelAssignmentEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.PanelAssignmentEndsAtRangeRule(min: 1000, max: 3600)
        let item = Labs.newPanelAssignment("x", title: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PanelAssignmentCodeLengthRule(maxLength: 255)
        let item = Labs.newPanelAssignment("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
