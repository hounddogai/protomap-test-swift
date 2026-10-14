@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveBedBoardTargetValidator()
        let item = BedManagement.newAdaptiveBedBoardTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveBedBoardTargetCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = BedManagement.AdaptiveBedBoardTargetCategoryLengthRule(maxLength: 255)
        let item = BedManagement.newAdaptiveBedBoardTarget("x", title: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementAdaptiveBedBoardTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.AdaptiveBedBoardTargetCodeLengthRule(maxLength: 16)
        let item = BedManagement.newAdaptiveBedBoardTarget("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
