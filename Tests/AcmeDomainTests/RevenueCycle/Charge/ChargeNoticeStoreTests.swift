@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeNoticeStore = RevenueCycle.newMemoryChargeNoticeStore()
        let item = RevenueCycle.newChargeNotice("code-262", name: "name-164")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
