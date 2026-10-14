@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationExceptionStore = RevenueCycle.newMemoryAuthorizationExceptionStore()
        let item = RevenueCycle.newAuthorizationException("code-959", title: "title-996")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
