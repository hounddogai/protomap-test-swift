@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryGlobalClaimAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.GlobalClaimAgreementStore = RevenueCycle.newMemoryGlobalClaimAgreementStore()
        let item = RevenueCycle.newGlobalClaimAgreement("code-990", name: "name-102")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
