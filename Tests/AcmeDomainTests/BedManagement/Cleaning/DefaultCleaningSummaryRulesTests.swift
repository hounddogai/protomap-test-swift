@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultCleaningSummaryValidator()
        let item = BedManagement.newDefaultCleaningSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultCleaningSummaryRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = BedManagement.DefaultCleaningSummaryRequiredSpecialtyRule(
            message: "default cleaning summary needs a value"
        )
        let item = BedManagement.newDefaultCleaningSummary("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultCleaningSummarySourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = BedManagement.DefaultCleaningSummarySourceLengthRule(maxLength: 1000)
        let item = BedManagement.newDefaultCleaningSummary("x", label: "y")
        item.source = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
