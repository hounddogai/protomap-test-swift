@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredRemittanceTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredRemittanceTemplateStore = RevenueCycle.newMemoryTieredRemittanceTemplateStore()
        let item = RevenueCycle.newTieredRemittanceTemplate("code-91", label: "label-56")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
