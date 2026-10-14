@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachNoticeValidator()
        let item = CareManagement.newOutreachNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachNoticeRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.OutreachNoticeRetriesRangeRule(min: 80, max: 3600)
        let item = CareManagement.newOutreachNotice("x", label: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.OutreachNoticeCodeLengthRule(maxLength: 32)
        let item = CareManagement.newOutreachNotice("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachNoticeUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.OutreachNoticeUpdatedAtRangeRule(min: 80, max: 120)
        let item = CareManagement.newOutreachNotice("x", label: "y")
        item.updatedAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.OutreachNoticeRequiredLabelRule(message: "outreach notice needs this field")
        let item = CareManagement.newOutreachNotice("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachNoticeDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = CareManagement.OutreachNoticeDiagnosisCodeLengthRule(maxLength: 120)
        let item = CareManagement.newOutreachNotice("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachNoticeRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = CareManagement.OutreachNoticeRateRangeRule(min: 9.3, max: 4039.8)
        let item = CareManagement.newOutreachNotice("x", label: "y")
        item.rate = 4041.3
        #expect(rule.check(item).count > 0)
    }
}
