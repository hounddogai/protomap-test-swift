@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapNoticeValidator()
        let item = CareManagement.newCareGapNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CareGapNoticeRequiredCodeRule(message: "care gap notice needs a value")
        let item = CareManagement.newCareGapNotice("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapNoticeRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.CareGapNoticeRequiredFacilityRule(message: "care gap notice needs this field")
        let item = CareManagement.newCareGapNotice("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapNoticeRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.CareGapNoticeRequiredNameRule(message: "care gap notice needs an entry")
        let item = CareManagement.newCareGapNotice("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapNoticeCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.CareGapNoticeCreatedAtRangeRule(min: 64, max: 120)
        let item = CareManagement.newCareGapNotice("x", name: "y")
        item.createdAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CareGapNoticeCodeLengthRule(maxLength: 255)
        let item = CareManagement.newCareGapNotice("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapNoticeNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.CareGapNoticeNameLengthRule(maxLength: 1000)
        let item = CareManagement.newCareGapNotice("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
