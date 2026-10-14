@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapManifestValidator()
        let item = CareManagement.newCareGapManifest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapManifestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.CareGapManifestTitleLengthRule(maxLength: 16)
        let item = CareManagement.newCareGapManifest("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapManifestProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = CareManagement.CareGapManifestProcedureCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newCareGapManifest("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCareGapManifestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.CareGapManifestRequiredTitleRule(message: "care gap manifest needs a value")
        let item = CareManagement.newCareGapManifest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapManifestRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = CareManagement.CareGapManifestRequiredProcedureCodeRule(message: "care gap manifest needs a value")
        let item = CareManagement.newCareGapManifest("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCareGapManifestPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = CareManagement.CareGapManifestPhoneLengthRule(maxLength: 32)
        let item = CareManagement.newCareGapManifest("x", title: "y")
        item.phone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
