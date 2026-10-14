@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimAgreementStore = RevenueCycle.newMemoryClaimAgreementStore()
        let item = RevenueCycle.newClaimAgreement("code-229", name: "name-710")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
