@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceTemplateStore = RevenueCycle.newMemoryRemittanceTemplateStore()
        let item = RevenueCycle.newRemittanceTemplate("code-424", title: "title-936")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
