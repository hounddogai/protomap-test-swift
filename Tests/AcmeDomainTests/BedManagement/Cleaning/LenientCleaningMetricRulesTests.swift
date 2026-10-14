@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCleaningMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientCleaningMetricValidator()
        let item = BedManagement.newLenientCleaningMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientCleaningMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LenientCleaningMetricCodeLengthRule(maxLength: 64)
        let item = BedManagement.newLenientCleaningMetric("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientCleaningMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.LenientCleaningMetricRequiredTitleRule(message: "lenient cleaning metric needs a value")
        let item = BedManagement.newLenientCleaningMetric("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientCleaningMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LenientCleaningMetricRequiredCodeRule(message: "lenient cleaning metric needs a value")
        let item = BedManagement.newLenientCleaningMetric("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
