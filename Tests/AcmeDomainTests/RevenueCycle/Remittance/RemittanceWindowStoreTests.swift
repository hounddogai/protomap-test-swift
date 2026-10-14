@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceWindowStore = RevenueCycle.newMemoryRemittanceWindowStore()
        let item = RevenueCycle.newRemittanceWindow("code-322", title: "title-155")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
