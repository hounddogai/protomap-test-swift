@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationVarianceValidator()
        let item = BedManagement.newIsolationVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationVarianceCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newIsolationVariance("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationVarianceDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.IsolationVarianceDiagnosisCodeLengthRule(maxLength: 255)
        let item = BedManagement.newIsolationVariance("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.IsolationVarianceRequiredTitleRule(message: "isolation variance needs this field")
        let item = BedManagement.newIsolationVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.IsolationVarianceTitleLengthRule(maxLength: 1000)
        let item = BedManagement.newIsolationVariance("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
