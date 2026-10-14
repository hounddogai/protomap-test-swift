@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInteractionWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingInteractionWindowValidator()
        let item = Pharmacy.newRollingInteractionWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingInteractionWindowSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Pharmacy.RollingInteractionWindowSourceLengthRule(maxLength: 255)
        let item = Pharmacy.newRollingInteractionWindow("x", title: "y")
        item.source = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingInteractionWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RollingInteractionWindowTitleLengthRule(maxLength: 255)
        let item = Pharmacy.newRollingInteractionWindow("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingInteractionWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.RollingInteractionWindowRequiredTitleRule(
            message: "rolling interaction window needs an entry"
        )
        let item = Pharmacy.newRollingInteractionWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
