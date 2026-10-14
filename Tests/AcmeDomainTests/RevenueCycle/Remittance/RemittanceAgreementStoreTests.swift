@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceAgreementStore = RevenueCycle.newMemoryRemittanceAgreementStore()
        let item = RevenueCycle.newRemittanceAgreement("code-535", title: "title-306")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
