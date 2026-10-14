@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationTemplateStore = RevenueCycle.newMemoryAuthorizationTemplateStore()
        let item = RevenueCycle.newAuthorizationTemplate("code-221", name: "name-606")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
