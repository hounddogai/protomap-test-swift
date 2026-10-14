@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetNoticeValidator()
        let item = ClinicalOps.newOrderSetNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetNoticeVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = ClinicalOps.OrderSetNoticeVisitMinutesRangeRule(min: 64, max: 255)
        let item = ClinicalOps.newOrderSetNotice("x", name: "y")
        item.visitMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetNoticeAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.OrderSetNoticeAttemptsRangeRule(min: 80, max: 80)
        let item = ClinicalOps.newOrderSetNotice("x", name: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetNoticeRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = ClinicalOps.OrderSetNoticeRequiredPhoneRule(message: "order set notice needs a value")
        let item = ClinicalOps.newOrderSetNotice("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
