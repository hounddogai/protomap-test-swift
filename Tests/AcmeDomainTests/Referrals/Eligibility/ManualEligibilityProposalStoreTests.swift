@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualEligibilityProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualEligibilityProposalStore = Referrals.newMemoryManualEligibilityProposalStore()
        let item = Referrals.newManualEligibilityProposal("code-707", title: "title-563")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
