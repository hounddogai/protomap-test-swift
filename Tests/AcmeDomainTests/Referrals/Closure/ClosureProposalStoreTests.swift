@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureProposalStore = Referrals.newMemoryClosureProposalStore()
        let item = Referrals.newClosureProposal("code-909", title: "title-314")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
