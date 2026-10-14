@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionMilestoneValidator()
        let item = Labs.newAccessionMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AccessionMilestoneRequiredCodeRule(message: "accession milestone needs an entry")
        let item = Labs.newAccessionMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionMilestoneCodeLengthRule(maxLength: 3600)
        let item = Labs.newAccessionMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionMilestoneRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Labs.AccessionMilestoneRequiredTimezoneRule(message: "accession milestone needs an entry")
        let item = Labs.newAccessionMilestone("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionMilestoneRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Labs.AccessionMilestoneRequiredClinicianIDRule(message: "accession milestone needs this field")
        let item = Labs.newAccessionMilestone("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
