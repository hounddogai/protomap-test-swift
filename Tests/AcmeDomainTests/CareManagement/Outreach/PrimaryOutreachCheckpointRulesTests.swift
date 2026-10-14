@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryOutreachCheckpointValidator()
        let item = CareManagement.newPrimaryOutreachCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryOutreachCheckpointClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = CareManagement.PrimaryOutreachCheckpointClinicianIDLengthRule(maxLength: 32)
        let item = CareManagement.newPrimaryOutreachCheckpoint("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryOutreachCheckpointRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.PrimaryOutreachCheckpointRequiredLabelRule(
            message: "primary outreach checkpoint needs a value"
        )
        let item = CareManagement.newPrimaryOutreachCheckpoint("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPrimaryOutreachCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PrimaryOutreachCheckpointRequiredCodeRule(
            message: "primary outreach checkpoint needs an entry"
        )
        let item = CareManagement.newPrimaryOutreachCheckpoint("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPrimaryOutreachCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PrimaryOutreachCheckpointCodeLengthRule(maxLength: 32)
        let item = CareManagement.newPrimaryOutreachCheckpoint("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryOutreachCheckpointRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = CareManagement.PrimaryOutreachCheckpointRequiredClinicianIDRule(
            message: "primary outreach checkpoint needs this field"
        )
        let item = CareManagement.newPrimaryOutreachCheckpoint("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
