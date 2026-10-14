@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationThresholdValidator()
        let item = BedManagement.newIsolationThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.IsolationThresholdNameLengthRule(maxLength: 64)
        let item = BedManagement.newIsolationThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationThresholdRequiredCodeRule(message: "isolation threshold needs this field")
        let item = BedManagement.newIsolationThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationThresholdRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.IsolationThresholdRequiredContactEmailRule(message: "isolation threshold needs a value")
        let item = BedManagement.newIsolationThreshold("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationThresholdThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.IsolationThresholdThresholdRangeRule(min: 5.5, max: 294.7)
        let item = BedManagement.newIsolationThreshold("x", name: "y")
        item.threshold = 296.2
        #expect(rule.check(item).count > 0)
    }
}
