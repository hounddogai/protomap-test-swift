@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualDenialAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualDenialAgreementStore = RevenueCycle.newMemoryManualDenialAgreementStore()
        let item = RevenueCycle.newManualDenialAgreement("code-198", name: "name-742")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
