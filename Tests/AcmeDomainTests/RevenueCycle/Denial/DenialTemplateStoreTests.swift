@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialTemplateStore = RevenueCycle.newMemoryDenialTemplateStore()
        let item = RevenueCycle.newDenialTemplate("code-459", title: "title-89")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
