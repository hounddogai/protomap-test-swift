@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeExceptionStore = RevenueCycle.newMemoryChargeExceptionStore()
        let item = RevenueCycle.newChargeException("code-327", title: "title-366")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
