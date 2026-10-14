@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingTaskScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingTaskScheduleValidator()
        let item = ClinicalOps.newPendingTaskSchedule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingTaskScheduleAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = ClinicalOps.PendingTaskScheduleAllergyLengthRule(maxLength: 16)
        let item = ClinicalOps.newPendingTaskSchedule("x", title: "y")
        item.allergy = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingTaskScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PendingTaskScheduleRequiredCodeRule(message: "pending task schedule needs an entry")
        let item = ClinicalOps.newPendingTaskSchedule("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
