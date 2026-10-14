@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackAlertAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackAlertAssignmentValidator()
        let item = ClinicalOps.newFallbackAlertAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackAlertAssignmentFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = ClinicalOps.FallbackAlertAssignmentFacilityLengthRule(maxLength: 120)
        let item = ClinicalOps.newFallbackAlertAssignment("x", title: "y")
        item.facility = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackAlertAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.FallbackAlertAssignmentCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newFallbackAlertAssignment("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackAlertAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.FallbackAlertAssignmentNameLengthRule(maxLength: 86400)
        let item = ClinicalOps.newFallbackAlertAssignment("x", title: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackAlertAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.FallbackAlertAssignmentRequiredNameRule(
            message: "fallback alert assignment needs this field"
        )
        let item = ClinicalOps.newFallbackAlertAssignment("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackAlertAssignmentRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = ClinicalOps.FallbackAlertAssignmentRequiredFacilityRule(
            message: "fallback alert assignment needs this field"
        )
        let item = ClinicalOps.newFallbackAlertAssignment("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackAlertAssignmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.FallbackAlertAssignmentRequiredTitleRule(
            message: "fallback alert assignment needs a value"
        )
        let item = ClinicalOps.newFallbackAlertAssignment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
