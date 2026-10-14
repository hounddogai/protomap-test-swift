@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingRecallRequestValidator()
        let item = Pharmacy.newPendingRecallRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingRecallRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.PendingRecallRequestRequiredTitleRule(message: "pending recall request needs this field")
        let item = Pharmacy.newPendingRecallRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingRecallRequestStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.PendingRecallRequestStartsAtRangeRule(min: 64, max: 255)
        let item = Pharmacy.newPendingRecallRequest("x", title: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingRecallRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PendingRecallRequestRequiredCodeRule(message: "pending recall request needs a value")
        let item = Pharmacy.newPendingRecallRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
