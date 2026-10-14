@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeAgreementStore = RevenueCycle.newMemoryChargeAgreementStore()
        let item = RevenueCycle.newChargeAgreement("code-152", name: "name-791")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
