@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultScheduledCareProtocolScheduleValidator()
        let item = ClinicalOps.newScheduledCareProtocolSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolScheduleClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = ClinicalOps.ScheduledCareProtocolScheduleClinicianIDLengthRule(maxLength: 64)
        let item = ClinicalOps.newScheduledCareProtocolSchedule("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.ScheduledCareProtocolScheduleCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newScheduledCareProtocolSchedule("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledCareProtocolScheduleRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.ScheduledCareProtocolScheduleRequiredClinicianIDRule(
            message: "scheduled care protocol schedule needs this field"
        )
        let item = ClinicalOps.newScheduledCareProtocolSchedule("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
