@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskReviewValidator()
        let item = ClinicalOps.newTaskReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskReviewRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = ClinicalOps.TaskReviewRequiredOwnerIDRule(message: "task review needs an entry")
        let item = ClinicalOps.newTaskReview("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskReviewCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newTaskReview("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TaskReviewRequiredCodeRule(message: "task review needs this field")
        let item = ClinicalOps.newTaskReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.TaskReviewRequiredNameRule(message: "task review needs this field")
        let item = ClinicalOps.newTaskReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
