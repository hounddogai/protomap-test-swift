@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationAgreementStore = RevenueCycle.newMemoryAuthorizationAgreementStore()
        let item = RevenueCycle.newAuthorizationAgreement("code-54", name: "name-173")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
