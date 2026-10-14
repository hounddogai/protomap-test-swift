@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedReferralProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedReferralProposalStore = Referrals.newMemoryWeightedReferralProposalStore()
        let item = Referrals.newWeightedReferralProposal("code-333", label: "label-942")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
