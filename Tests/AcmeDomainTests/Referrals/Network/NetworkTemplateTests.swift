@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkTemplateTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newNetworkTemplate("code-420", label: "label-562")
        #expect(item.status == Referrals.NetworkTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Referrals.newNetworkTemplate("code-420", label: "label-562")
        try item.moveTo(Referrals.NetworkTemplateStatus.cancelled)
        #expect(item.status == Referrals.NetworkTemplateStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newNetworkTemplate("code-420", label: "label-562")
        item.status = Referrals.NetworkTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkTemplateStatus.planned) }
    }
}
