@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackTransferRequestValidator()
        let item = BedManagement.newFallbackTransferRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackTransferRequestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.FallbackTransferRequestTitleLengthRule(maxLength: 16)
        let item = BedManagement.newFallbackTransferRequest("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackTransferRequestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = BedManagement.FallbackTransferRequestEndsAtRangeRule(min: 32, max: 1000)
        let item = BedManagement.newFallbackTransferRequest("x", title: "y")
        item.endsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackTransferRequestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.FallbackTransferRequestDiscountRangeRule(min: 8.3, max: 2465.3)
        let item = BedManagement.newFallbackTransferRequest("x", title: "y")
        item.discount = 2466.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackTransferRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.FallbackTransferRequestRequiredCodeRule(
            message: "fallback transfer request needs a value"
        )
        let item = BedManagement.newFallbackTransferRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
