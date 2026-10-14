@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualDenialTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualDenialTemplateStore = RevenueCycle.newMemoryManualDenialTemplateStore()
        let item = RevenueCycle.newManualDenialTemplate("code-110", title: "title-137")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
